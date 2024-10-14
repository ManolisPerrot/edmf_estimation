library(reticulate)
# https://rstudio.github.io/reticulate/articles/versions.html
# Sys.setenv(PYTHONUSERBASE="/home/hourdin/miniconda3/envs/python38/")
# Sys.setenv(RETICULATE_PYTHON = "/home/hourdin/.local/lib/HighTune-pyhton3.8")
# export RETICULATE_PYTHON=~/.local/lib/HighTune-pyhton3.8
# export RETICULATE_PYTHON=/home/hourdin/miniconda3/envs/python38/bin/python

print("OKA")
#use_python("/usr/bin/python3.8")
#use_python("/home/hourdin/.local/lib/HighTune-pyhton3.8/bin/python3")
#use_python("/home/hourdin/miniconda3/envs/python38/bin/python")
#use_python("/home/hourdin/.local/lib/HighTune-pyhton3.8")
print("OK1")

#  backtracing
#options(error = function(e) print(rlang::trace_back()))
#reticulate::use_condaenv(condaenv = "python38", conda = "/home/hourdin/miniconda3/bin/conda", required=T)

#use_condaenv(condaenv = "python38", conda = "/home/hourdin/miniconda3/bin/conda", required=T)

#conda_list()
#py_discover_config()
#py_config()
#repl_python()

#py_run_string("import scipy")
#scipy <- import_from_path("scipy", path="/home/hourdin/miniconda3/envs/python38/lib/python3.8/site-packages/")
scipy <- import("scipy")
scipy$amin(c(1,3,5,7))

py_config()

print("scipy version")
print(py_get_attr(scipy, "__version__"))
