"""Compute metrics on all given cases and store as csv file.
Main usage:
```bash
python compute_metrics_les.py metric_name1 [-tol tolerance1] metric_name2 [-tol tolerance2] ...
```
where:
- $metric1 is the name of the metric (summary statistic) in the form caseId_metricType
- $tolerance to error (~tolerated standard deviation)
"""

import csv
import omldb
from summary_statistics import metric_type_catalog
from cli_utils import get_script_arguments


def compute_metrics(metrics_names):
    """
    Compute metrics from LES cases in oMLDb

    Parameters
    ----------
    case_ids : list of str, optional
        List of case IDs to use. If None, uses all available cases.

    Returns
    -------
    dict
        Dictionary mapping case_id to BLD value
    """
    print("Computing LES metrics from oMLDb...")

    # Load catalog
    omldb.build_catalog()
    catalog = omldb.load_catalog()

    # Filter for LES cases
    les_catalog = catalog[catalog["data_type"] == "les"]

    # Extract case_ids (reminder: metrics_names is a list of caseID_MetricType)
    case_ids = [arg.rsplit("_", 1)[0] for arg in metrics_names]

    if case_ids is None:
        # Use all available LES cases
        case_ids = les_catalog["case_id"].tolist()
    else:
        # Validate requested cases exist
        available = set(les_catalog["case_id"])
        case_ids = [cid for cid in case_ids if cid in available]
        if not case_ids:
            raise ValueError("None of the requested case_ids found in database")

    print(f"Processing {len(case_ids)} LES cases...")

    metrics = {}
    for i, metric_name in enumerate(metrics_names):
        case_id, metric_type = metric_name.rsplit("_", 1)
        try:
            print(f"  Loading {case_id}...")
            ds = omldb.load_case(case_id)
            metadata = omldb.load_case_metadata(case_id)
            metrics[metric_name] = metric_type_catalog(metric_type)(ds, metadata)

        except Exception as e:
            print(f"  Warning: Could not process {case_id}: {e}")
            continue

    if not metrics:
        raise ValueError("No LES cases could be processed successfully")

    return metrics


### Main script ###
if __name__ == "__main__":
    _, metrics_names, tolerances = get_script_arguments(expect_prefix_args=0)
    output_file = "cibles.csv"
    metrics = compute_metrics(metrics_names)

    with open(output_file, mode="w", newline="") as file:
        writer = csv.writer(file, quoting=csv.QUOTE_NONE, escapechar=" ")  # No quotes
        writer.writerow(["TYPE"] + metrics_names)  # Write header row
        writer.writerow(["MEAN"] + [metrics[name] for name in metrics_names])
        writer.writerow(
            ["VAR"] + [str(tolerance ** 2) for tolerance in tolerances]
        )

    print(f"\n Successfully computed metrics for {len(metrics)} cases")
    print(f"\n Metrics temporarily written in {output_file} during the current wave.")
