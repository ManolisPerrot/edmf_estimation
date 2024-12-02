#!/bin/bash
# this script fetches and compiles edmf_ocean at a manually specified version.
# to see what is the latest version, go to https://github.com/ManolisPerrot/edmf_ocean.git
# /!\ DO NOT modify the library edmf_ocean, since it will cause conflicts with the latest version 
# in the edmf_ocean repo /!\
#
# Additionally, some functions in likelihood_mesonh ensure that versions of .so
# libraries are compatible with the version below.

set -e
set -x

# enter here the version you want to utilize, based on git hash
VERSION=a80098b137f5051814cd16d13afdca1038374274

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