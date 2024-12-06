#!/bin/bash

cat > cibles_all.csv <<eod
TYPE,FC_TH,FC_dz,WC_TH,WC_dzTH,WC_U,WC_dzU
MEAN,0,0,0,0,0,0
VAR,1e-12,1e-12,1e-12,1e-12,1e-12,1e-12
eod


#!/bin/bash

if [[ $1 == "-metrics" ]]; then
    shift
    metrics=("$@")
    # Combine metrics into a comma-separated list
    metrics_str=$(printf ",%s" "${metrics[@]}")
    metrics_str=${metrics_str:1} # Remove the leading comma
    # Use csvcut to extract columns
    csvcut -c TYPE,"$metrics_str" cibles_all.csv > cibles.csv
else
    echo "Usage: $0 -metrics <metric1> <metric2> ... <metricN>"
    exit 1
fi
