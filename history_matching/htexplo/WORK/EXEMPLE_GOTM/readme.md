# Basic usage

```bash
bash convergence_loop_for_exemple.sh -metrics {CaseId}_{MetricType} [--tol tolerance]
```
- `{CaseId}` can be an id found in `omldb.build_catalog()`, or `ALLCases`
- `{MetricType}` can be found in `summary_statistics.metric_type_catalog()`, or `ALLMetricTypes`

Additional arguments:
- `sample_size_next_design`: number of SCM evaluations at each wave. Recommantdation is 10*number of parameters
- `sample_size`: number of Gaussian Process evaluations
- `nroy_treshold`: if remaining space between wave N and wave N+1 is not reduced more than this treshold, the loop stops
- `wave_max=15`: maximum number of waves