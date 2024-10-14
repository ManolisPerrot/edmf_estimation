#!/bin/bash
#set -vx


######################################################################
# Author : Frédéric Hourdin (LMDZ team)
# Setting up the LMDZ SCM for HightTune explorer
# 2019/02/21
######################################################################

ROOT=`pwd`
echo $ROOT

rad=rrtm
rad=oldrad # Much faster compilation. Good for tests

netcdf=/home/hourdin/LMDZ/pub/netcdf4_hdf5_seq # Not to recompile netcdf
netcdf=1
netcdf=/home/hourdin/LMDZ/pub

echo '#####################################################################'
echo  Choosing the LMDZ version
echo  List of available versions on 
echo  http://www.lmd.jussieu.fr/~lmdz/pub/src/Readme
echo  $version can be "trunk" or something like "20210320.trunk"
echo 'A particular svn release could be chosen as well (experts only)'
echo '#####################################################################'

# Definition of the LMDZ version. It is the option passed to install_lmdz.sh

version='-v 20221201.trunk'
version='-unstable -v 20230210.trunk'
version='-v 20230412.trunk'
version='-v 20230626.trunk'
version='-unstable -v 20230920.trunk -r 4706' # Solving a bug on arm_cu
version='-v 20231022.trunk'
version='-v 20240508.trunk'


LMDZ=LMDZ`echo $version | sed -e 's/-v//g' -e 's/-unstable//' -e 's/-r/r/' -e 's/ //g'`


echo '#####################################################################'
echo ' Checking if model already exists'
echo '#####################################################################'

LMDZroot=""
if [ -d $ROOT/../../$LMDZ ] ; then
   LMDZroot=$ROOT/../..
else
   # By default, LMDZ is installed next to HighTune
   LMDZroot=$ROOT/..
fi
LMDZdir=$LMDZroot/$LMDZ
echo LMDZdir $LMDZdir

# Could be written with "sed -i" but this option is not safe on MacOSX
sed -e 's:LMDZdir=.*.$:LMDZdir='$LMDZdir':' -e 's/^rad=.*$/rad='$rad'/' $ROOT/models/LMDZ/serie_LMDZ.sh >| tmp
\mv -f tmp $ROOT/models/LMDZ/serie_LMDZ.sh
chmod +x $ROOT/models/LMDZ/serie_LMDZ.sh

echo '#####################################################################'
echo ' Installing LMDZ if needed'
echo ' To force reinstalling, you should run'
echo ' \rm -rf LMDZtrunk'
echo '#####################################################################'

if [ ! -d $LMDZdir ] ; then
   echo LMDZ directory called $LMDZdir does not exists
   echo LMDZ installation will start within 3 seconds
   sleep 3
   cd $LMDZroot
   wget http://lmdz.lmd.jussieu.fr/pub/install_lmdz.sh -O install_lmdz.sh
   echo Installing LMDZ, output in `pwd`/install_lmdz$$.out ';' Might take minutes

   ncopt=
   if [ $netcdf != 1 -a -d $netcdf ] ; then ncopt="-netcdf `ls -d $netcdf`" ; fi
   echo ./install_lmdz.sh $version -bench 0 $ncopt -name $LMDZ
   bash ./install_lmdz.sh $version -bench 0 $ncopt -name $LMDZ > install_lmdz$$.out 2>&1
   cd $LMDZ
   wget http://lmdz.lmd.jussieu.fr/pub/1D/1D.tar.gz ; tar xvf 1D.tar.gz
   cd -
   # Changing the default debug option for compilation
   sed -i'' -e '/opt_comp=.*.debug/s/-debug//' -e 's/^rad=.*$/rad='$rad'/' $LMDZ/1D/bin/compile
   sed -i'' -e '/opt_compile=.*.debug/s/-debug//' -e 's/^rad=.*$/rad='$rad'/' $LMDZ/1D/run.sh
   cd -
else
   echo $LMDZdir Already exists
   echo No need to reinstall

fi
echo '#####################################################################'
echo ' End of setup_LMDZ.sh'
echo '#####################################################################'
