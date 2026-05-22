import numpy as np


def density_eos(t, s, rho0, T0, S0, alpha, beta):
    """Density calculation from given temp and salinity"""
    density = rho0 * (1.0 - alpha * (t - T0) + beta * (s - S0))
    return density


def bld_averaged(density, z):
    """OSBL depth corresponding to max N2"""
    N2 = np.gradient(-density, z, axis=1)
    bld_vals = np.zeros(len(N2[:, 0]))
    dz = z[1] - z[0]

    nz = N2.shape[1]

    for t_idx in range(N2.shape[0]):
        i = N2[t_idx, :].argmax()

        # --- handle boundaries ---
        if i == 0 or i == nz - 1:
            # no interpolation possible → just take grid value
            bld_vals[t_idx] = z[i]
        else:
            # quadratic interpolation
            f_1, f0, f1 = N2[t_idx, i - 1], N2[t_idx, i], N2[t_idx, i + 1]
            denom = (f_1 - 2.0 * f0 + f1)

            if denom == 0:  # avoid division by zero
                bld_vals[t_idx] = z[i]
            else:
                delta = (f_1 - f1) / (2.0 * denom)
                bld_vals[t_idx] = z[i] + delta * dz

    return np.nanmean(bld_vals)


def read_linear_eos_data(metadata):
    rho0 = metadata["gotm"]["equation_of_state/rho0"]
    T0 = metadata["gotm"]["equation_of_state/linear/T0"]
    S0 = metadata["gotm"]["equation_of_state/linear/S0"]
    alpha = metadata["gotm"]["equation_of_state/linear/alpha"]
    beta = metadata["gotm"]["equation_of_state/linear/beta"]
    return rho0, T0, S0, alpha, beta


def mld4h(ds, metadata):
    hours = 4
    # last time
    last_time = ds.time.max().values
    # target time
    target = last_time - np.timedelta64(hours, "h")
    # index of closest time
    idx = abs(ds.time.values - target).argmin()
    # corresponding time
    closest_time = ds.time.values[idx]
    # actual offset in hours
    actual_hours = (last_time - closest_time) / np.timedelta64(1, "h")
    # print(f"Requested average: {hours} h")
    # print(f"Due to dataset structure, average is performed in pratice on: {actual_hours:.3f} h")
    # Extract variables from the dataset
    z = ds["z"].values
    temp = ds["temp"].values
    salt = ds["salt"].values

    rho0, T0, S0, alpha, beta = read_linear_eos_data(metadata)
    density = density_eos(
        t=temp[idx:], s=salt[idx:], rho0=rho0, T0=T0, S0=S0, alpha=alpha, beta=beta
    )
    # Compute metric
    return bld_averaged(density, z)


def mld12h(ds, metadata):
    hours = 12
    # last time
    last_time = ds.time.max().values
    # target time
    target = last_time - np.timedelta64(hours, "h")
    # index of closest time
    idx = abs(ds.time.values - target).argmin()
    # corresponding time
    closest_time = ds.time.values[idx]
    # actual offset in hours
    # actual_hours = (last_time - closest_time) / np.timedelta64(1, "h")
    # print(f"Requested average: {hours} h")
    # print(f"Due to dataset structure, average is performed in pratice on: {actual_hours:.3f} h")
    # Extract variables from the dataset
    z = ds["z"].values
    temp = ds["temp"].values
    salt = ds["salt"].values

    rho0, T0, S0, alpha, beta = read_linear_eos_data(metadata)
    density = density_eos(
        t=temp[idx:], s=salt[idx:], rho0=rho0, T0=T0, S0=S0, alpha=alpha, beta=beta
    )
    # Compute metric
    return bld_averaged(density, z)


def metric_type_catalog(metric_type=None):
    """Lists all the metric types"""
    catalog = {"mld4h": mld4h, "mld12h": mld12h}
    if not metric_type:
        return catalog
    else:
        try:
            return catalog[metric_type]
        except:  # noqa: E722
            raise KeyError("Metric type not found")


def default_tolerance(metric_type: str) -> float:
    """Default tolerance for a given metric type

    Parameters
    ----------
    metric_type : str

    Returns
    -------
    float
        default tolerance

    Raises
    ------
    KeyError
        if input metric type does not exists
    """
    tolerances = {"mld4h": 1.0, "mld12h": 1.0}
    try:
        return tolerances[metric_type]
    except:  # noqa: E722
        raise KeyError("Metric type not found")
