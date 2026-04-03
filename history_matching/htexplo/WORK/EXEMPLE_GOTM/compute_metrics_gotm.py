#!/usr/bin/env python
"""
Compute metrics for gotm ouputs.
Main usage:
```bash
python compute_metrics_gotm.py $wavenumber metric_name1 [-tol tolerance1] metric_name2 [-tol tolerance2] ...
```
where:
- $metric1 is the name of the metric (summary statistic) in the form caseId_metricType
- $tolerance to error (~tolerated standard deviation), optional. Tolerance comes from the full example.sh script, but is not used here. 
"""

import numpy as np
from scipy.io import netcdf_file
import re
import subprocess
import sys
from pathlib import Path
from multiprocess import (
    Pool,
)  # multiprocessING cannot handle locally defined functions, multiprocess can
import csv
from summary_statistics import metric_type_catalog
import xarray as xr
from warnings import warn
import omldb
from cli_utils import get_script_arguments


def get_gotm_config_for_case(case_id):
    """
    Get the GOTM configuration file path for a given LES case

    Parameters
    ----------
    case_id : str
        Case ID from oMLDb

    Returns
    -------
    Path
        Path to the GOTM yaml configuration file
    """

    case_path = omldb.get_case_path(case_id)

    # Look for GOTM yaml file in the case directory
    # Assuming it's named gotm.yaml or gotm_{case_id}.yaml
    yaml_files = list(case_path.glob("gotm.yaml"))

    if not yaml_files:
        raise FileNotFoundError(
            f"No GOTM yaml file found for case {case_id} in {case_path}"
        )

    return yaml_files[0]


def modif_config_file(in_file, out_file, new_params):
    """Modify configuration file with new sets of parameters"""
    with open(in_file, "r") as sources:
        lines = sources.readlines()

    with open(out_file, "w") as sources:
        for line in lines:
            for key, value in new_params.items():
                pattern = rf"^(\s*{re.escape(key)}\s*:\s*).*$"
                line = re.sub(pattern, r"\g<1>" + str(value), line)
            sources.write(line)


def run_gotm(config, run_dir):
    """
    Run GOTM simulation in a specific directory

    Parameters
    ----------
    config : str or Path
        Path to GOTM configuration file
    run_dir : str or Path
        Directory to run GOTM in
    """
    # Create log files
    stdout_log = run_dir / "gotm_stdout.log"
    stderr_log = run_dir / "gotm_stderr.log"
    command = ["gotm", "--ignore_unknown_config", config]
    out_file = run_dir / "gotm_out.nc"

    # --- Clean previous output (IMPORTANT) ---
    if out_file.exists():
        out_file.unlink()

    # ------- Run simulation
    with open(stdout_log, "w") as fout, open(stderr_log, "w") as ferr:
        subprocess.run(command, check=True, stdout=fout, stderr=ferr, cwd=str(run_dir))


def gotm_run_valid(run_dir):
    """
    Returns True if gotm_out.nc exists and looks valid.
    """
    out_file = Path(run_dir) / "gotm_out.nc"

    # File exists?
    if not out_file.exists():
        warn(f"GOTM run failed in {run_dir}: gotm_out.nc has not been created")
        return False

    # Try opening it
    try:
        ds = xr_opendataset_gotm(out_file)
    except Exception:
        warn(f"GOTM run failed in {run_dir}: Invalid NetCDF output")
        return False

    # Check it’s not empty
    if ds.dims.get("time", 0) == 0:
        warn(f"GOTM run failed in {run_dir}: Empty dataset")
        return False
    # Check it does not contain NaN
    if np.isnan(ds.temp).any() or np.isnan(ds.salt).any():
        warn(f"GOTM run failed in {run_dir}: Temperature or salinity contains NaN")
        return False
    return True


def simulation_wrapper(params, case_configs, param_list, runs_dir):
    """
    Run GOTM simulation for each LES case

    Parameters
    ----------
    params : array-like
        Parameter values to test
    case_configs : dict
        Dictionary mapping case_id to original GOTM config file path
    param_list : list of str
        List of parameter names
    runs_dir : str or Path
        Base directory for GOTM runs

    Returns
    -------
    None
    """
    params = np.asarray(params)
    runs_dir = Path(runs_dir)
    runs_dir.mkdir(parents=True, exist_ok=True)

    # Create parameter dictionary
    new_params = {}
    for idx, p in enumerate(params):
        new_params[param_list[idx]] = p

    # Run GOTM for each case
    for case_id in case_ids:
        # Create run directory for this case and iteration
        case_run_dir = runs_dir / case_id
        case_run_dir.mkdir(parents=True, exist_ok=True)

        # Get original config for this case
        original_config = case_configs[case_id]

        # Create modified config
        modified_config = case_run_dir / "gotm_modified.yaml"
        modif_config_file(original_config, modified_config, new_params)

        # Run GOTM
        try:
            run_gotm("gotm_modified.yaml", case_run_dir)
        except Exception as e:
            print(f"  Error running GOTM for {case_id}: {e}")
            continue


def xr_opendataset_gotm(path, **kwargs):
    """
    Load gotm NetCDF outputs, as would do xarray.
    Currently, xarray cannot open gotm ouputs since z and zi are both coordinates and variables of time and space (for e.g. surface following coordinates).
    When z and zi does not depend on time and space, this function is a fix based on Qing Li's gotmtool.model.load_data().

    Parameters
    ----------
    path : array-like
        Parameter values to test

    Returns
    -------
    xarray.dataset
        The corresponding dataset, where z and zi are only coordinates and no more space-time varying variables.
    """
    # load z and zi
    with netcdf_file(path, "r", mmap=False) as ncfile:
        nc_z = ncfile.variables["z"]
        nc_zi = ncfile.variables["zi"]
        z = xr.DataArray(
            nc_z[0, :, 0, 0],
            dims=("z"),
            coords={"z": nc_z[0, :, 0, 0]},
            attrs={"long_name": nc_z.long_name.decode(), "units": nc_z.units.decode()},
        )
        zi = xr.DataArray(
            nc_zi[0, :, 0, 0],
            dims=("zi"),
            coords={"zi": nc_zi[0, :, 0, 0]},
            attrs={
                "long_name": nc_zi.long_name.decode(),
                "units": nc_zi.units.decode(),
            },
        )
    # load other variables
    out = xr.load_dataset(
        path,
        drop_variables=["z", "zi"],
        **kwargs,
    )
    out = out.assign_coords(
        {
            "z": z,
            "zi": zi,
        }
    )
    out = out.assign_coords(
        {
            "z_2d": (("time", "z"), nc_z[:, :, 0, 0]),
            "zi_2d": (("time", "zi"), nc_zi[:, :, 0, 0]),
        }
    )
    for var in out.data_vars:
        if "z" in out.data_vars[var].dims:
            out.data_vars[var].assign_coords({"z": z})
        elif "zi" in out.data_vars[var].dims:
            out.data_vars[var].assign_coords({"zi": zi})
    # return a reorderd view
    return out.transpose("time", "z", "zi", "lon", "lat")


def compute_one_metric(metric_name, penalization=1e10):
    """
    Compute one metric type on one case for ALL varying parameters (labelled by runID)

    Parameters
    ----------
    metric_name : str
        metric name of the form caseID_metricType

    Returns
    -------
    list
        List of metric_type computed on all parameter evaluation labelled by runID
    """
    case_id, metric_type = metric_name.rsplit("_", 1)
    metadata = omldb.load_case_metadata(case_id)
    metric = []
    for run_id in run_ids:
        case_run_dir = runs_dir / run_id / case_id
        if gotm_run_valid(case_run_dir):
            ds = xr_opendataset_gotm(
                case_run_dir / "gotm_out.nc"
            )  # in gotm outputs, z and zi are both coordinates and variables, which makes xarray crash
            val = metric_type_catalog(metric_type)(ds, metadata)
            metric.append(val)
        else:  # penalize gotm crash
            les = omldb.load_case(case_id)
            metadata = omldb.load_case_metadata(case_id)
            val = penalization + metric_type_catalog(metric_type)(les, metadata)
            metric.append(val)
    return metric


def parameter_file_to_dic(param_file):
    """
    Read parameter ascii file

    Parameters
    ----------
    param_file: ascii file produced by htune_convertDesign.R

    Returns
    -------
    dict
    """
    # Initialize an empty dictionary
    param_dict = {}
    # Open the file and read lines
    with open(param_file, "r") as file:
        # Read the first line (header) and strip quotes
        header_line = file.readline().strip()
        headers = [header.strip('"') for header in header_line.split()]

        # Store the headers as the first entry in the dictionary
        param_dict["t_IDs"] = headers[1:]  # Skip the first header entry, "t_IDs"

        # Read the remaining lines for data entries
        for line in file:
            # Split line into identifier and data values
            parts = line.strip().split()
            key = parts[0].strip('"')  # First item is the identifier, without quotes
            values = [
                float(value) for value in parts[1:]
            ]  # Convert remaining values to floats

            # Add to dictionary
            param_dict[key] = values
    return param_dict


###############
# Main script
###############

if __name__ == "__main__":
    # ------- Read script input
    debug = False
    if debug:
        waven = 1
        metrics_names = ["LES_IDEAL_GARANAIK2023_C01_mld4h"]
    else:
        waven_str, metrics_names,tol = get_script_arguments(expect_prefix_args=1)
        waven = int(waven_str[0])
    case_ids = [
        arg.rsplit("_", 1)[0] for arg in metrics_names
    ]  # extract case_ids on which to run GOTM
    print("\n" + "=" * 60)
    print("Loading GOTM configurations")
    print("=" * 60)
    runs_dir = Path(f"WAVE{waven}/runs")
    runs_dir.mkdir(parents=True, exist_ok=True)
    # structure of the simulation repository : WAVE{waven}/runs/SCM-{waven}-{run_id}/{case_id}/ gotm_modified.yaml and gotm.out

    case_configs = {}
    print(case_ids)
    for case_id in case_ids:
        config_path = get_gotm_config_for_case(case_id)
        case_configs[case_id] = config_path
        print(f"  {case_id}: {config_path}")

    if not case_configs:
        raise ValueError("No GOTM configuration files found for any cases")

    # ------- Read ensembles of parameters
    param_file = f"Par1D_Wave{waven}.asc"
    param_dict = parameter_file_to_dic(param_file)

    # ------- Run cases in parrallel
    metrics = {}

    # Define the task to parallelize for each run
    def task(run_id):
        print(f"\n Running single-column model {run_id}")
        return simulation_wrapper(
            param_dict[run_id], case_configs, param_dict["t_IDs"], runs_dir / run_id
        )

    L = list(param_dict.keys())[1:]

    with Pool() as p:
        out = p.map(task, list(param_dict.keys())[1:])

    run_ids = list(param_dict.keys())[1:]

    # ------- Compute metrics (i.e. summary statistics)
    for m_name in metrics_names:
        metrics[m_name] = compute_one_metric(m_name)

    # ------- Write output file
    output_file = "Metrics.csv"
    with open(output_file, mode="w", newline="") as file:
        writer = csv.writer(file, quoting=csv.QUOTE_NONE, escapechar=" ")  # No quotes
        writer.writerow(["SIM"] + metrics_names)  # Write header row

        vals_inline = [metrics[key] for key in metrics]

        for i, run_id in enumerate(run_ids):
            row = [run_id] + [
                float(vals_inline[k][i]) for k in range(len(vals_inline))
            ]  # Exclude repeated run_id
            writer.writerow(row)
