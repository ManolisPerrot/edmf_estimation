# cli_utils.py
import argparse
from summary_statistics import default_tolerance,metric_type_catalog
import omldb

def get_script_arguments(expect_prefix_args: int = 0):
    """_summary_

    Parameters
    ----------
    expect_prefix_args : int, optional
        number of exepected prefix arguments, before metric arguments. Default 0.

    Returns
    -------
    _type_
        _description_
    """    
    parser = argparse.ArgumentParser(
        usage="%(prog)s [prefix args] metric1 [--tol tol1] metric2 ...",
        formatter_class=argparse.RawTextHelpFormatter
    )

    #  Only add if needed
    if expect_prefix_args > 0:
        parser.add_argument("prefix", nargs=expect_prefix_args)

    args, unknown = parser.parse_known_args()

    #  Handle prefix safely
    prefix = args.prefix if expect_prefix_args > 0 else []

    items = unknown

    metrics_names = []
    explicit_tols = []

    i = 0

    while i < len(items):
        metric_name = items[i]

        if i + 2 < len(items) and items[i+1] == "--tol":
            tol = float(items[i+2])
            i += 3
        else:
            tol = None  
            i += 1

        metrics_names.append(metric_name)
        explicit_tols.append(tol)

    new_metrics_names = handle_ALL(metrics_names)

    new_tolerances = []

    for metric_name, tol in zip(metrics_names, explicit_tols):
        expanded = handle_ALL([metric_name])

        for m in expanded:
            _, MetricType = m.rsplit("_", 1)

            # Rule: ALLMetricTypes → always default tol
            if "ALLMetricTypes" in metric_name:
                new_tolerances.append(default_tolerance(MetricType))

            elif tol is not None:
                new_tolerances.append(tol)

            else:
                new_tolerances.append(default_tolerance(MetricType))

    return prefix, new_metrics_names, new_tolerances

def get_ALLCasesId():
    catalog = omldb.build_catalog(verbose=False)
    return [CaseId for CaseId in catalog['case_id']]

def get_ALLMetricTypes():
    return list(metric_type_catalog().keys())

def handle_ALL(metrics_names):
    new_metrics_names = metrics_names.copy()
    ALLCasesId = get_ALLCasesId()
    ALLMetricTypes = get_ALLMetricTypes()

    ALLCases_ALLMetricTypes = [
        f"{CaseId}_{MetricType}"
        for CaseId in ALLCasesId
        for MetricType in ALLMetricTypes
    ]

    for metric_name in metrics_names:
        CaseId,MetricType = metric_name.rsplit("_", 1)
        if CaseId == 'ALLCases':
            if not MetricType == 'ALLMetricTypes':
                ALLCases_MetricType = [f'{id}_{MetricType}' for id in ALLCasesId]
                new_metrics_names.remove(metric_name)
                new_metrics_names += ALLCases_MetricType
            else:
                new_metrics_names = ALLCases_ALLMetricTypes
                break 
        else:
            if MetricType == 'ALLMetricTypes':
                CaseId_ALLMetricType = [f'{CaseId}_{m}' for m in ALLMetricTypes]
                new_metrics_names.remove(metric_name)
                new_metrics_names += CaseId_ALLMetricType
                
    return new_metrics_names