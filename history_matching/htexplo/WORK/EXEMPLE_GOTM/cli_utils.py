import argparse
from summary_statistics import default_tolerance

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
    tolerances = []

    i = 0

    while i < len(items):
        metric_name = items[i]

        if i + 2 < len(items) and items[i+1] == "--tol":
            tol = float(items[i+2])
            i += 3
        else:
            _, metric_type = metric_name.rsplit("_", 1)
            tol = default_tolerance(metric_type)
            i += 1

        metrics_names.append(metric_name)
        tolerances.append(tol)

    return prefix, metrics_names, tolerances