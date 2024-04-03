#!/usr/bin/env python
# coding: utf-8

###########################################
# Imports
###########################################

import sys  # to put the SCM into the PYTHONPATH
sys.path.append('edmf_ocean/library/F2PY')
from sys import exit
import time as TIME
import xarray as xr
from scipy.interpolate import interp1d
import scipy.signal
from scm_class import SCM
from netCDF4 import Dataset
import matplotlib.pyplot as plt
import numpy as np
from case_configs import case_params, default_params
from multiprocess import Pool #multiprocessING cannot handle locally defined functions, multiprocess can
import subprocess

#################Functions to check edmf_ocean versions##########################
def get_expected_version():
  with open("./fetch_and_compile_edmf_ocean.sh", "r") as fp:
    lines = fp.readlines()
    for line in lines:
      if line.startswith("VERSION"):
        version = line.split("=")[1].replace('\n', '')
        return version
  return "unknown"

def get_current_version():
  return subprocess.getoutput("cd ./edmf_ocean && git rev-parse HEAD")

def check_edmf_ocean_version():
  expected_version = get_expected_version()
  current_version = get_current_version()
  if expected_version != current_version:
     raise Exception(f"Version conflict for edmf_ocean: you need to run ./fetch_and_compile_edmf_ocean.sh, expected version={expected_version}, current version={current_version}")
###########################################

