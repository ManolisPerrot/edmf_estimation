import numpy as np
import xarray as xr
import matplotlib.pyplot as plt
from pathlib import Path
from compute_metrics_gotm import gotm_run_valid, xr_opendataset_gotm



# =========================
# Running statistics (Welford)
# =========================
def update_stats(mean, M2, count, new_value):
    count += 1
    delta = new_value - mean
    mean += delta / count
    delta2 = new_value - mean
    M2 += delta * delta2
    return mean, M2, count


# =========================
# Core computation
# =========================
def compute_profiles(wave):
    rundir = Path(f'WAVE{wave}/runs')
    
    stats = {}
    z_ref = None  # store z from first valid file
    
    for run_dir in rundir.iterdir():
        if not run_dir.is_dir():
            continue
        
        for case_dir in run_dir.iterdir():
            if not case_dir.is_dir():
                continue
            
            case_id = case_dir.name
            file = case_dir / "gotm_out.nc"
            
            if not file.exists():
                continue
            
            try:
                # Open efficiently
                ds =xr_opendataset_gotm(file)
                
                # Extract last timestep
                temp = ds["temp"].isel(time=-1).values  # shape (z,)
                
                # Get z once
                if z_ref is None:
                    if "z" in ds:
                        z_ref = ds["z"].values
                    else:
                        z_ref = np.arange(len(temp))
                
                ds.close()
                
            except Exception:
                # skip corrupted/crashed runs
                continue
            
            # Initialize stats if needed
            if case_id not in stats:
                stats[case_id] = {
                    "mean": np.zeros_like(temp),
                    "M2": np.zeros_like(temp),
                    "count": 0
                }
            
            s = stats[case_id]
            s["mean"], s["M2"], s["count"] = update_stats(
                s["mean"], s["M2"], s["count"], temp
            )
    
    # Finalize mean/std
    results = {}
    for case_id, s in stats.items():
        if s["count"] < 2:
            continue
        
        variance = s["M2"] / (s["count"] - 1)
        std = np.sqrt(variance)
        
        results[case_id] = {
            "mean": s["mean"],
            "std": std,
            "count": s["count"]
        }
    
    return results, z_ref


# =========================
# Plotting
# =========================
def plot_profiles(results, z):
    n = len(results)
    
    fig, axes = plt.subplots(1, n, figsize=(4*n, 6), sharey=True)
    
    if n == 1:
        axes = [axes]
    
    for ax, (case_id, data) in zip(axes, sorted(results.items())):
        mean = np.squeeze(data["mean"])
        std = data["std"]
        
        ax.plot(mean, z, label="mean")
        ax.fill_betweenx(z, mean - std, mean + std, alpha=0.3, label="±std")
        
        ax.set_title(f"{case_id}\n(n={data['count']})")
        ax.set_xlabel("Temperature")
        ax.invert_yaxis()
        ax.grid()
    
    axes[0].set_ylabel("Depth (z)")
    
    plt.tight_layout()
    plt.show()


# =========================
# Main
# =========================
if __name__ == "__main__":
    wave = 1
    
    results, z = compute_profiles(wave)
    plot_profiles(results, z)