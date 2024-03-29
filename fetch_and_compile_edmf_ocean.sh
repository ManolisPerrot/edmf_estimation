#!/bin/bash
# this script fetches and compiles edmf_ocean at a manually specified version.
# to see what is the latest version, go to https://github.com/ManolisPerrot/edmf_ocean.git
# DO NOT modifiy the library edmf_ocean
# Python functions are in likelihood_mesonh to check that versions are compatible

set -e
set -x

VERSION=7784a84ba69401834a0860661009bdff18dcdca8

if test -d edmf_ocean; then
    cd edmf_ocean
    git fetch 
    git checkout ${VERSION}
    cd library/fortran_src && make
else
    git clone https://github.com/ManolisPerrot/edmf_ocean.git edmf_ocean
    cd edmf_ocean && git checkout ${VERSION}
    cd library/fortran_src && make
fi