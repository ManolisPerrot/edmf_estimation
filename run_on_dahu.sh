#!/bin/bash
# -- set project name --
#OAR --project pr-plume
# -- set job name
#OAR -n test_job
# -- Set resources and walltime
#OAR -l /core=1,walltime=00:28:00
# -- load environment --
source /applis/environments/conda.sh
conda activate baseMano

cd /home/PROJECTS/pr-plume/edmf_estimation

# running...
python3 test.py
    
     
