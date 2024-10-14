#!/bin/bash

set +e ; conda deactivate > /dev/null 2>&1 ; set -e # Starts by deactivating conda in case
#set -vx


########################################################################
#======================================================================#
#----------------------------------------------------------------------#
#|               1. OPTIONS                                           |#
#======================================================================#
########################################################################

#----------------------------------------------------------------------------
# Special tricks to deactivate the git clone and so when the network
# is not available. Can be used only after the setup.sh has been run succesfully
# once
#----------------------------------------------------------------------------
network=on # on/off

#----------------------------------------------------------------------------
# Old (ExeterUQ) or new (ExeterUQ_MOGP) of Exter UQ programs
#----------------------------------------------------------------------------

ExeterUQ=ExeterUQ_MOGP

#----------------------------------------------------------------------------
# Choice between pip or conda install fo python
#----------------------------------------------------------------------------

python_install=conda
python_install=pip3

python=python3 # or python
conda_main=~/miniconda3          #  for puthon_install=conda


#----------------------------------------------------------------------------
# arguments
#----------------------------------------------------------------------------

if [ $# = 0 ] ; then
    MODEL=""
else
    case $1 in
       -h|-help|--help) cat <<eod
Use : setup.sh -h [Model_Name [EXPE_NAME]]
$0 alone will only check R and python installation
Model_Name name among :
eod
          ls  models | cat
          exit 1 ;;
       *) MODEL=$1
          if [ ! -d models/$MODEL ] ; then
             echo models/$MODEL does not exists
             $0 -h ; exit 1
          fi
          if [ $# = 1 ] ; then
             EXP=$MODEL
          else
             EXP=$2
          fi ;;
    esac
fi


#======================================================================#
# Specific environment
#======================================================================#
hostname=`hostname` ; echo $hostname
hostname_reduced=$hostname
case ${hostname:0:6} in
   #-----------
   "jean-z") cat > env.sh <<eod
                module purge
                compilo=19.0.4 # available 2013.0, 2017.2
                module load intel-compilers/\$compilo
                module load intel-mpi/\$compilo
                module load hdf5/1.10.5/intel-\$compilo-mpi
                module load netcdf/4.7.0/intel-\$compilo-mpi
                module load netcdf-fortran/4.4.5/intel-\$compilo-mpi
                module load subversion/1.9.7/gcc-4.8.5
                module load intel-mkl/\$compilo
                module load nco
                module load cdo
                module load ferret
                module load r
                module load python/2.7.16
                login=`whoami` ; groupe=`echo \$login | cut -c2-4`
                # Inputation de la consommation sur le groupe \$groupe
                # Peut se changer a la main :
                # groupe=gzi
                submit="sbatch -A \${groupe}@cpu "
                run="srun --label -n "
                SCRATCHD=\$SCRATCH
                STORED=\$STORE
                LMDZD=\$WORK
eod
      hostname_reduced=jean-zay
      ;;

   #----------------------------------
   "spirit")  cat > env.sh <<eod
                module load python/meso-3.8
eod
      hostname_reduced=spirit
      python_install=pip3
      ;;

   #----------------------------------
   "pxtrop") if [[ "$hostname" == "pxtropics11" ]] ; then
             msg="export LD_LIBRARY_PATH=$HOME/.local/lib/:$LD_LIBRARY_PATH"
           else
             msg="#echo No special environment needed on this computer"
           fi
             cat > env.sh <<eod 
$msg
eod
      ;;
   *) cat > env.sh <<eod
                #echo No special environment needed on this computer
eod
esac

chmod +x env.sh
source ./env.sh

########################################################################
#======================================================================#
#|           2. CHECKING PACKAGES INSTALLATION                        |#
#======================================================================#
########################################################################

#-----------------------------------------------------------------------
# Insure the same version of mogp tools will be used 
# with this version of the HighTune project
#-----------------------------------------------------------------------
# This commit corresponds to the last one on devel 
# Author: Eric Daub <45598892+edaub@users.noreply.github.com>
# Date:   Wed Jun 3 18:18:33 2020 +0100
# mogp_commit=8dd1b6f76b93c8b96540f240b0dc0d6739892d00
# 19 fevrier 2021 : last commit on master
#-----------------------------------------------------------------------

mogp_commit=ecec9
case $mogp_commit in
  ecec9) 
    python_version_max=3.8
    numpy_version="==1.17.4" 
    scipy_version="==1.7.1" 
    patsy_version="==0.5.1"
    matplotlib_version="==3.2.2"
    pandas_version="==1.2.3"
    ;;
esac

#-----------------------------------------------------------------------
# Python environment for reticulate R package : pip/conda
#-----------------------------------------------------------------------

case $python_install in

   pip3)   PYTHONUSERBASE= ; RETICULATE_PYTHON=`which $python`
           python_install_package="$python -m pip install --user -r" ;;

   conda)  conda_python=python38-HighTune
           if [ ! -d $conda_main ] ; then
               echo $0 \n $conda_main : no such directoty
               cat <<___________________________________________________eod
               Trying to use HighTune with conda but does not find conda.

               If wanting to run without conda, try to change 
               -------------------------------
               change python_install=conda -> pip3 in setup.sh

               If wanting to install miniconda :
               ---------------------------------
               wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
               bash Miniconda3-latest-Linux-x86_64.sh
               ~/miniconda3/bin/conda config --set auto_activate_base false
___________________________________________________eod
               exit 1
           elif [ ! -d $conda_main/envs/$conda_python ] ; then
               echo $conda_main/envs/$conda_python
               $conda_main/bin/conda create --yes --name $conda_python python=3.8
           fi
           PYTHONUSERBASE=$conda_main/envs/$conda_python
           RETICULATE_PYTHON=$conda_main/envs/$conda_python/bin/python
           python_install_package="conda install -y --file"
           # In a bash, you should run "source activate" instead of "conda activate"
           source $conda_main/bin/activate $conda_python ;;

   *) echo in $0 \n echo Python environment $python_install not available ; exit 1

esac

#-----------------------------------------------------------------------
# Checking if python is not too recent
#-----------------------------------------------------------------------

which $python
python_version=`$python --version | awk ' { print $2 } ' | cut -d. -f1-2`
echo $python_version $python_version_max
if [ `echo $python_version $python_version_max | awk ' { print ( $1 - $2 ) * 1000  } '` -lt 0 ] ; then
    echo Python version $python_version should be '<=' $python_version_max ; exit 1
fi


#-----------------------------------------------------------------------
# Testing availability of various programs
# Should not be moved before activating conda or not
#-----------------------------------------------------------------------

for exe in R Rscript cdo ncks $python $python_install ; do
    if [ "`which $exe`" = "" ] ; then echo You need $exe ; exit 1 ; fi
done

#-----------------------------------------------------------------------
# Python setup
#-----------------------------------------------------------------------

if [ $network = on ] ; then
if [ $ExeterUQ = ExeterUQ_MOGP ] ; then
    if [ ! -d mogp_emulator ] ; then
      git clone https://github.com/alan-turing-institute/mogp_emulator
    fi 
    cd mogp_emulator
    req=requirements_$mogp_commit
    git checkout $mogp_commit
    cp requirements.txt ${req}
    sed -i'' "s/^numpy.*$/numpy$numpy_version/g" ${req}
    sed -i'' "s/^scipy.*$/scipy$scipy_version/g" ${req}
    echo "netcdf4"                       >> ${req}
    echo "matplotlib$matplotlib_version" >> ${req}
    echo "pandas$pandas_version"         >> ${req}
    echo "patsy$patsy_version"           >> ${req}
    $python_install_package ${req}
    if [ $? != 0 ] ; then exit 1 ; fi
    sed -i'' -e "s/license=..MIT..,/license=\'MIT\',/" setup.py
    $python setup.py install --user
    cd ..

    #-------------------------------------------------------------------
    # Needed R packages
    # Following R documentations, using ~/.Renviron to specify
    # where the R packages should be installed by a non root user
    # include R version and hostname in the directory of install
    #-------------------------------------------------------------------
    rversion=`R --version | head -1 | awk ' { print $3 } '`
    R_LIBS_USER=~/.local/lib/r-HighTune/${hostname_reduced}-R${rversion}-${python_install}
    mkdir -p $R_LIBS_USER 
    cat > ~/.Renviron <<_____________________________________________eod
      R_LIBS_USER=$R_LIBS_USER
      PYTHONUSERBASE=$PYTHONUSERBASE
      RETICULATE_PYTHON=$RETICULATE_PYTHON
_____________________________________________eod
    eval src/CheckInstallPackages.sh reticulate invgamma GenSA far fields lhs maps mco ncdf4 shape tensor withr loo MASS pracma mvtnorm flexclust tmvtnorm tictoc ars HI coda MfUSampler 

    if [ "$?" != "0" ] ; then echo Problem encountered when installing R packages ; exit 1 ; fi
else
    # When using the original version of ExeterUQ, should install rstan
    # Touchy ...
    eval src/CheckInstallPackages.sh reticulate invgamma GenSA far fields lhs maps mco ncdf4 shape tensor withr loo MASS rstan
    if [ "$?" != "0" ] ; then echo Problem encountered when installing R packages ; exit 1 ; fi
fi # if [ $network = on ] ; then
fi # if [ $ExeterUQ = ExeterUQ_MOGP ] ; then

#-----------------------------------------------------------------------
# Insure the same version of ExeterUQ tools will be used 
# with this version of the HighTune project
#-----------------------------------------------------------------------
# This commit corresponds to the last one on master
# Merge: 089036e e284f7e
# Author: vicvolodina93 <52710405+vicvolodina93@users.noreply.github.com>
# Date:   Thu Jun 4 07:59:41 2020 +0100
# exeter_commit=9e45cde952d75c10515646f412226f6072606b81
# exeter_commit=ef50736999f1879f19759ca84655a326e7a6b74d
# 19/02/2021 : exeter_commit=1cdb5c5fedb266e196627336b23ba02cc1375c0a
# 23/02/2021 : exeter_commit=c67cacb47363389ca767fed5ba30d4a82fb13a2d
# 25/02/2021 : exeter_commit=7dd118fc0d3da1c3441be2712a6b09a1257e166a
# 26/02/2021 : exeter_commit=283afc55e10e40e147726827e75cbd3a7dde06e0
# 01/03/2021
#-----------------------------------------------------------------------

exeter_commit=06b008a50b1598d44c9e94a679482ec0896d6cd0
isnew=0
if [ ! -d $ExeterUQ ] ; then
   git clone https://github.com/BayesExeter/$ExeterUQ 
   isnew=1
fi 
cd $ExeterUQ
if [ $ExeterUQ = ExeterUQ_MOGP ] ; then git checkout $exeter_commit ; fi

### Bricolage momentané
# patch pour que ça marche en 2D (2 paramètres) (Naj)
if [ $isnew -eq 1 ] ; then
  patch HistoryMatching/HistoryMatching.R ../src/patchs/patch_HistoryMatching
fi
cd ..




echo '======================================================================'
echo '            3. CONFIGURING THE SPECIFIC EXPERIMENT                    '
echo '======================================================================'

if [ "$MODEL" = "" ] ; then 
  mkdir -p WORK/EXEMPLE/
  cp src/exemple.sh WORK/EXEMPLE/
  cd WORK/EXEMPLE/
  bash exemple.sh setup
  bash exemple.sh 1
  echo "CHECK RESULTS IN WORK/EXEMPLE/"
  exit 
fi

echo '-----------------------------------------------------------------------'
echo ' Possibility to have a setup_* specific of a given model'
echo '-----------------------------------------------------------------------'
if [ -f models/$MODEL/setup_$MODEL.sh ] ; then models/$MODEL/setup_$MODEL.sh ; fi

echo '-----------------------------------------------------------------------'
echo ' Download the data relevant to the current experiment'
echo '-----------------------------------------------------------------------'

if [ "$MODEL" = "ECRAD" ] ; then
  
  if [ ! -d LES1D_ecRad ] ; then
     echo Downloading LES/MC results for radiation
     #wget http://simu:visu2018@www.umr-cnrm.fr/visu-high-tune/data_tuningtool/LES1D_ecRad.tar
     # Naj: temporary change
     wget https://web.lmd.jussieu.fr/~nvillefranque/pub/data/LES1D_ecRad.tar
     tar xvf LES1D_ecRad.tar
     \rm -rf LES1D_ecRad.tar
  fi
  
  if [ ! -d RAD ] ; then
     echo Downloading LES/MC results for radiation
     #wget http://simu:visu2018@www.umr-cnrm.fr/visu-high-tune/data_tuningtool/RAD.tar
     # Naj: temporary change
     wget https://web.lmd.jussieu.fr/~nvillefranque/pub/data/RAD.tar
     tar xvf RAD.tar
     \rm -rf RAD.tar
  fi

else

  if [ ! -d LES ] ; then
     echo Downloading LES results from CNRM and LMD
     wget http://simu:visu2018@www.umr-cnrm.fr/visu-high-tune/data_tuningtool/les.tar
     if [ ! -f les.tar ] ; then echo Can not download les.tar ; exit 1 ; fi
     tar xvf les.tar
     \rm -f les.tar
#-----------------------------------------------------------------------
     # Bricolage avec le cas RCE oceanique. A reprendre
     cd LES/RCE_OCE/ ; mv REF DAILY ; mkdir -p REF
     for i in 0 1 ; do
        cdo daymean DAILY/LES$i.nc REF/LES$i.nc
        ncks -v zf DAILY/LES$i.nc -A REF/LES$i.nc
        ncrename -d z,levf REF/LES$i.nc  -O
        # On prend le calendrier du cas LMDZ1D en attendant mieux.
        # Avec le nouveau format, devrait permettre d'etre propre
        # Tous les cas idealises au 1er janvier 2000 ?
        ncatted -a "units","time",o,c,"days since 1997-11-01 00:00:00" REF/LES$i.nc -O
     done

     cd -
     mv LES/RCE_OCE LES/RCEOCE
#-----------------------------------------------------------------------
     # on supprime le repertoire gabls4 provenant de la base de donnee CNRM-LMD et on le 
     # remplace par celui du leslmd.tar (avec le bon calendrier)
     \rm -rf LES/GABLS4
     wget --no-check-certificate http://www.lmd.jussieu.fr/~lmdz/HighTune/leslmd.tar
     if [ ! -f leslmd.tar ] ; then echo Can not download leslmd.tar ; exit 1 ; fi
     tar xvf leslmd.tar
     \rm -f leslmd.tar
  fi

fi

echo '-----------------------------------------------------------------------'
echo ' Creating and installing the working directory WOR/$EXP/log'
echo '-----------------------------------------------------------------------'

DIR0=`pwd`

mkdir -p WORK/$EXP/log
cp src/*.py src/*.sh src/*.R WORK/$EXP/
cp -r models/$MODEL/* WORK/$EXP/

cd WORK/$EXP
if [ "$MODEL" = "ECRAD" ] ; then
  ln -s $DIR0/RAD .
else
  ln -s $DIR0/LES .
fi
#ln -s $DIR0/$ExeterUQ/BuildEmulator .

### Bricolage momentané
#patch while waiting daniel to do the comit
#on ExetreUQ package 
cp -r $DIR0/$ExeterUQ/BuildEmulator .
mv BuildEmulator_tmp.R BuildEmulator/BuildEmulator.R

if [ ! -d HistoryMatching ]  ; then
  ln -s $DIR0/$ExeterUQ/HistoryMatching .
fi 
if [ ! -d mogp_emulator ] ; then
  ln -s $DIR0/mogp_emulator .
fi

cp $DIR0/env.sh .
