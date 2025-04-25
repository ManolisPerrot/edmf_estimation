# edmf_estimation: Uncertainty Quantification tools for edmf_ocean 

This repo contains Uncertainty Quantification tools (UQ) applied to the oceanic turbulence 1D model edmf_ocean. 
It relies on the advantageous implementation of edmf_ocean: a Python interface (using F2PY), coupled to Fortran 90 routines.

Contains:
- Global Sensitivity Analysis via Sobol' Analysis
- Bayesian Calibration via MCMC (DE-Metropolis-Z algorithm)
- Calibration via emulated History Matching (htexplo tool)

## Installation
todo: check permissions...



1. Clone this github repo.
2. Create a specific environment (baseMano) `conda env create -f environment.yml`, and activate `conda activate baseMano`
3. Download and install edmf_ocean model running `bash fetch_and_compile_edmf_ocean.sh`. If compilation succeeded, the last prompt should be `FORTRAN SCM TOOLS OK`. 
4. Download the LES (Large Eddy Simulation) reference datasets here https://zenodo.org/records/13149047. Reference data are in tests/data/. Copy this /data folder into the repo main folder edmf_estimation. To perform UQ, two reference datasets are available: FC500 (free convection) and W005_C500. 
Alternatively, description of the datasets and documentation to retrieve the data is provided here https://github.com/plumehub/docs.
`case_configs.py` contains informations used to run edmf_ocean. Additional cases can be configured via this file.

**Troubleshooting Compilation errors (step 2):** if compilation failed, go to edmf_estimation/edmf_ocean/library/fortran_src and check that the .so files that were generated match the .so filenames written in `makefile`. If they do not match, change the names in the makefile by the one created in the folder (typically, replacing `scmoce.cpython-311-x86_64-linux-gnu.so` by `scmoce.cpython-364-x86_64-linux-gnu.so` ). Then recompile.  

## Sobol Analysis

The method is described in chap. 4 of Manolis Perrot PhD thesis. 

Scripts are contained in `edmf_estimation/sobol_analysis`. For each script, a doc is provided at the beginning of the script.

To perform sensitivity analysis:
1. Draw `n` evaluations of the model via `draw_samples.py`
2. Compute Sobol indices with `sobol_analysis_from_samples.py`
3. Plot results w/ `plot_sensitivity_analysis.py`

To check convergence of the method: perform sensitivity analysis with different `n`, then use `plot_sensitivity_to_nsamples.py` to check convergence of the method. 

## MCMC Bayesian Inference

Scripts are contained in the main folder `edmf_estimation`.
It performs Bayesian estimation using MCMC sampling via DE-Metropolis-Z algorithm, using the `pymc` package (https://www.pymc.io/):

1. `MCMC_inference.py` performs the MCMC analysis, and save the results into `MCMC_outputs/`
2. MCMC is based on the evaluation of the model and the computation of likelihood (=data-model mismatch), calling at each evaluation `likelihood_mesonh.py`. This likelihood is based on a $L^2$ cost function on temperature. Options include adding velocities and TKE in the cost function. Additionally, a cost function based on gradients ($H^1$ norm) can be used. 
3. `MCMC_pairplot.py` allows to plot the 1D and 2D marginals of the posterior probability distribution estimated by MCMC
4. `MCMC_quality_plot.py` allows to check quality of MCMC by plotting mixture of the chains, Effective Sample Size and Rhat.

Finally, one can compare variability of the outputs before (i.e. from the prior distribution) and after calibration (i.e. from the posterior distribution) running `andrew_plot_prior.py` and `andrew_plot.py`, respectively. 

## Calibration with History Matching

[in the folder `history_matching/htexplo/WORK/EXEMPLE_OCEAN`]

Using the tool `htexplo` (reference paper of the method: Couvreux et al. (2021) https://doi.org/10.1029/2020MS002217 )

### Installation

htexplo requires old version of numpy and scipy, while edmf_ocean requires newer versions. 
One need to create another specific conda environment, named (hightune):

`cd history_matching/htexplo/WORK/EXEMPLE_OCEAN/`
`conda env create -f environment.yml`

Then to install specific modules:

`conda activate hightune`
`bash history_matching/htexplo/setup.sh`

(Then debug/install the missing packages, in particular for R. The section 'Installation Rstudio' from htexplo doc `history_matching/htexplo/Readme` could be useful.) 

### Usage

First, make sure you have activated (baseMano) env, and not (hightune). 
Our implementation is NOT based on the general scipt `bench.sh`, but on the simpler script `exemple.sh` in EXEMPLE_OCEAN.  

To run one wave of history matching, run `exemple.sh`:
- several options can be given in arguments, regarding number of waves, or metric used
- parameters range can be modified in this file
- this script is calling `compute_metrics.py` to compute LES/SCM metrics
- cleaning of previous runs can be performed with `exemple.sh clean`

To compute several waves until a convergence criterion is attained, run `convergence_loop_for_exemple.sh`



## Variational Inference via SequentialMeasureTransport.jl

TODO




