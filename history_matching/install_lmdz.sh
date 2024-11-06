#!/bin/bash

#set -vx

###########################################################################
# Author : Laurent Fairhead et Frédéric Hourdin
# Usage  : install_lmdz.sh -help
#
# bash installation script of the LMDZ model on different computer types :
# Linux PC, "mesocentre" (IPSL-UPMC, IPSL-X), super-computer (IDRIS)
#
# The model is downloaded in the following directory tree
# $MODEL/modipsl/modeles/...
# using the "modipsl" infrastructure created by the "IPSL"
# for coupled (atmosphere/ocean/vegetation/chemistry) climate modeling
# activities.
# Here we only download atmospheric (LMDZ) and vegetation (ORCHIDEE)
# components.
#
# The sources of the models can be found in the "modeles" directory.
# In the present case, LMDZ, ORCHIDEE, and IOIPSL or XIOS (handling of
# input-outputs using the NetCDF library).
#
# The script downloads various source files (including a version of NetCDF)
# and utilities, compiles the model, and runs a test simulation in a
# minimal configuration.
#
# Prerequisites : pgf90/gfortran, bash or ksh, wget , gunzip, tar, ...
#
# Modif 18/11/2011
#    changes for option real 8.
#      We compile with -r8 (or equivalent) and -DNC_DOUBLE for the GCM
#      but with -r4 for netcdf. Variable real must be set to
#      r4 or r8 at the beginning of the script below.
#
###########################################################################

echo install_lmdz.sh DEBUT `date`
set -e

################################################################
# Choice of installation options
################################################################

################################################################
# A function to fetch files either locally or on the internet
################################################################
function myget { #1st and only argument should be file name
    # Path on local computer where to look for the datafile
    if [ -f /u/lmdz/WWW/LMDZ/pub/$1 ] ; then
        \cp -f -p /u/lmdz/WWW/LMDZ/pub/$1 .
    elif [ -f ~/LMDZ/pub/$1 ] ; then
        \cp -f -p ~/LMDZ/pub/$1 .
    else
        wget --no-check-certificate -nv http://lmdz.lmd.jussieu.fr/pub/$1
        save_pub_locally=0
        if [ $save_pub_locally = 1 ] ; then # saving wget files on ~/LMDZ/pub
            dir=~/LMDZ/pub/`dirname $1` ; mkdir -p $dir
            cp -r `basename $1` $dir
        fi
    fi
}

# 04_2021 : tester si r4 marche encore !
#real=r4
real=r8


#########################################################################
# Valeur par défaut des parametres
#########################################################################
svn=""
#version=trunk
version=20231022.trunk

getlmdzor=1
netcdf=1   #  1: for automatic installation;
#          or 0: do not install NetCDF and look for it in standard locations;
#          or absolute path: look for NetCDF there
check_linux=1
ioipsl=1
bench=1
pclinux=1
pcmac=0 # default: not on a Mac
compiler=gfortran
if [ `gfortran -dumpversion | cut -d. -f1` -ge 10 ] ; then allow_arg_mismatch="-fallow-argument-mismatch" ; fi
SCM=0
# surface/vegetation scheme treatment
# controlled by the single variable veget which can have the following values
# - NONE: bucket scheme (default)
# - CMIP6: orchidee version used in CMIP exercise, rev 5661
# - number: orchidee version number
veget=NONE
# choose the resolution for the bench runs
# grid_resolution= 32x24x11 or 48x36x19 for tests (test without ORCHIDEE)
#                  96x71x19  standard configuration
grid_resolution=144x142x79
grid_resolution=96x95x39
grid_resolution=48x36x19
grid_resolution=32x32x39
# choose the physiq version you want to test
#physiq=NPv6.0.14splith
physiq=

## parallel can take the values none/mpi/omp/mpi_omp
parallel=mpi_omp
parallel=none
idris_acct=lmd
trusting=testing
OPT_GPROF=""
OPT_MAKELMDZ=""
MODEL=""

## also compile XIOS? (and more recent NetCDF/HDF5 libraries) Default=no
with_xios="n"
opt_makelmdz_xios=""

## compile with oldrad/rrtm/ecrad radiatif code (Default=rrtm)
rad=rrtm

## compile_with_fcm=1 : use makelmdz_fcm (1) or makelmdz (0)
compile_with_fcm=1

#Compilation with Cosp (cosp=NONE/v1/v2 ; default=NONE)
cosp=NONE
opt_cosp=""

# Check if on a Mac
if [ `uname` = "Darwin" ]
then
    pcmac=1
    export MAKE=make
fi
#echo "pcmac="$pcmac

env_file=""

#########################################################################
#  Options interactives
#########################################################################
while (($# > 0))
do
    case $1 in
        "-h") cat <<........fin
    $0 [ -v version ] [ -r svn_release ]
           [ -parallel PARA ] [ -d GRID_RESOLUTION ] [ -bench 0/1 ]
           [-name LOCAL_MODEL_NAME] [-gprof] [-opt_makelmdz] [-rad RADIATIF]

    -v       "version" like 20150828.trunk
             see http://www.lmd.jussieu.fr/~lmdz/Distrib/LISMOI.trunk

    -r       "svn_release" : either the svn release number or "last"

    -compiler gfortran|ifort|pgf90 (default: gfortran)

    -parallel PARA : can be mpi_omp (mpi with openMP) or none (for sequential)

    -d        GRID_RESOLUTION should be among the available benchs if -bench 1
              among which : 48x36x19, 48x36x39
              if wanting to run a bench simulation in addition to compilation
              default : 48x36x19

    -bench     activating the bench or not (0/1). Default 1

    -testing/unstable 

    -name      LOCAL_MODEL_NAME : default = LMDZversion.release

    -netcdf    0, 1 or PATH
                   0: do not download NetCDF, look for it in standard locations
               1: download and compile NetCDF
                   PATH: full path to an existing installed NetCDF library

    -xios      also download and compile the XIOS library
               (requires the NetCDF4-HDF5 library, also installed by default)
               (requires to also have -parallel mpi_omp)

    -gprof     to compile with -pg to enable profiling with gprof

    -cosp      to run without our with cospv1 or cospv2 [none/v1/v2]

    -rad RADIATIF can be oldrad, rrtm or ecrad radiatif code

    -nofcm     to compile without fcm

    -SCM        install 1D version automatically

    -debug      compile everything in debug mode

    -opt_makelmdz     to call makelmdz or makelmdz_fcm with additional options

    -physiq    to choose which physics package to use

    -env_file  specify an arch.env file to overwrite the existing one

    -veget surface model to run [NONE/CMIP6/xxxx]

........fin
              exit ;;
        "-v") version=$2 ; shift ; shift ;;
        "-r") svn=$2 ; shift ; shift ;;
        "-compiler") compiler=$2
                     case $compiler in
                         "gfortran"|"ifort"|"pgf90") compiler=$2 ; shift
                                                     shift ;;
                         *) echo "Only gfortran , ifort or pgf90 for the " \
                                 "compiler option"
                            exit
                     esac ;;
        "-d") grid_resolution=$2 ; shift ; shift ;;
        "-gprof") OPT_GPROF="-pg" ; shift ;;
        "-unstable"|"-testing") trusting=`echo $1 | cut -c2-`  ; shift ;;
        "-cosp") cosp=$2
                 case $cosp in
                     "none"|"v1"|"v2") cosp=$2 ; shift ; shift ;;
                     *) echo Only none v1 v2 for cosp option ; exit
                 esac ;;
        "-nofcm") compile_with_fcm=0 ; echo This option will be reactivated soon '(promesse du 8dec2022)' ; exit 1 ;  shift ;;
        "-SCM") SCM=1 ; shift ;;
        "-opt_makelmdz") OPT_MAKELMDZ="$2" ; shift ; shift ;;
        "-rrtm") rrtm="$2"
                 if [ "$2" = "false" ] ; then
                     rad="oldrad"
                 else
                     rad="rrtm"
                 fi
                 shift ; shift ;;
        "-rad") rad=$2
                case $rad in
                    "oldrad"|"rrtm"|"ecrad") rad=$2 ; shift ; shift ;;
                    *) echo Only oldrad rrtm ecrad for rad option ; exit
                esac ;;
        "-parallel") parallel=$2
                     case $parallel in
                         "none"|"mpi"|"omp"|"mpi_omp") parallel=$2 ; shift
                                                       shift ;;
                         *) echo Only none mpi omp mpi_omp for the parallel \
                                 option
                            exit
                     esac ;;
        "-bench") bench=$2 ; shift ; shift ;;
        "-debug") optim=-debug ; shift ;;
        "-name") MODEL=$2 ; shift ; shift ;;
        "-netcdf") netcdf=$2 ; shift ; shift ;;
        "-physiq") physiq=$2 ; shift ; shift ;;
        "-xios") with_xios="y" ; shift ;;
        "-env_file") env_file=$2 ; shift ; shift ;;
        "-veget") veget=$2 ; shift ; shift ;;
        *)  bash install_lmdz.sh -h ; exit
    esac
done

# Option de compilation du rayonnement : depend de $mysvn ><= r4185,
# sera donc definie plus bas

#opt_rad=""
#case $rad in
#   rrtm) opt_rad="-rad rrtm" ;;
#   ecrad) opt_rad="-rad ecrad" ;;
#esac


# Option de compilation pour Cosp
opt_cosp=""
case $cosp in
    v1) opt_cosp="-cosp true" ;;
    v2) opt_cosp="-cospv2 true" ;;
esac

# Check on veget version
#if [ "$veget" != 'NONE'  -a "$veget" != "CMIP6" -a "$veget" != +([0-9]) ] ; then
if [ $veget != 'NONE'   -a $veget != "CMIP6" ] ; then
    re='^[0-9]+$'
    if ! [[ $veget =~ $re ]] ; then
        echo 'Valeur de l option veget non valable'
        exit
    fi
fi

#Define veget-related suffix for gcm name
if [ "$veget" = 'NONE' ] ; then
    suff_orc=''
    #For use with tutorial, orchidee_rev is also defined (will be
    #written in surface_env at the end of the script)
    orchidee_rev=''
else
    suff_orc='_orch'
fi


if [ $parallel = none ] ; then
    sequential=1; suff_exe='_seq'
else
    sequential=0; suff_exe='_para_mem'
fi

#Chemin pour placer le modele
if [ "$MODEL" = "" ] ; then MODEL=./LMDZ$version$svn$optim ; fi


arch=local


if [ $compiler = g95 ] ; then echo g95 is not supported anymore ; exit ; fi

################################################################
# Specificite des machines
################################################################

hostname=`hostname`
if [ "$pclinux" = 1 ] ; then o_ins_make="-t g95" ; else o_ins_make="" ; fi

case ${hostname:0:5} in

    jean-)   compiler="mpiifort" ;
             par_comp="mpiifort" ;
             o_ins_make="-t jeanzay" ;
             make=gmake ;
             module purge
	     module load gcc/6.5.0
             module load intel-compilers/19.0.4 ;
             #module load intel-mpi/19.0.4 ;
             #module load intel-mkl/19.0.4 ;
             module load hdf5/1.10.5-mpi ;
             module load netcdf/4.7.2-mpi ;
             module load netcdf-fortran/4.5.2-mpi ;
             module load subversion/1.9.7 ;
	     module load cmake
             export NETCDF_LIBDIR=./
             export NETCDFFORTRAN_INCDIR=./
             export NETCDFFORTRAN_LIBDIR=./
             arch=X64_JEANZAY ;;

    cicla|camel)   compiler="gfortran" ;
                   module purge
                   module load gnu/10.2.0
                   module load openmpi/4.0.5
                   module load hdf5/1.10.7-mpi
                   module load netcdf-c/4.7.4-mpi
                   module load netcdf-fortran/4.5.3-mpi
                   netcdf=/net/nfs/tools/PrgEnv/linux-scientific6-x86_64/gcc-10.2.0/netcdf-fortran-4.5.3-k3drgfqok3lip62hnm3tsyof4cjen5sk
                   module load svn/1.14.0

                   if [ $parallel != none ] ; then
                       root_mpi=/net/nfs/tools/meso-sl6/openmpi/4.0.5-gcc-10.2.0
                       path_mpi=$root_mpi/bin ;
                       par_comp=${path_mpi}/mpif90 ;
                       mpirun=${path_mpi}/mpirun ;
                   fi ;
                   arch=local  ;
                   make=make ;
                   o_ins_make="-t g95" ;;

    *)       if [ $parallel = none -o -f /usr/bin/mpif90 ] ; then
                 path_mpi=`which mpif90 | sed -e s:/mpif90::` ;
                 if [ -d /usr/lib64/openmpi ] ; then
                     root_mpi="/usr/lib64/openmpi"
                 else
                     root_mpi="/usr"
                 fi
             else
                 echo "Cannot find mpif90" ;
                 if [ $parallel = none ] ; then exit ; fi ;
             fi ;
             if [ $parallel != none ] ; then
                 root_mpi=$(which mpif90 | sed -e s:/bin/mpif90::)
                 path_mpi=$(which mpif90 | sed -e s:/mpif90::)
                 export LD_LIBRARY_PATH=${root_mpi}/lib:$LD_LIBRARY_PATH
             fi
             par_comp=${path_mpi}/mpif90 ;
             mpirun=${path_mpi}/mpirun ;
             arch=local  ;
             make=make ;
             o_ins_make="-t g95"
esac

# Flags for parallelism:
if [ $parallel != none ] ; then
    # MPI_LD are the flags needed for linking with MPI
    MPI_LD="-L${root_mpi}/lib -lmpi"
    if [ "$compiler" = "gfortran" ] ; then
        # MPI_FLAGS are the flags needed for compilation with MPI
        MPI_FLAGS="-fcray-pointer"
        # OMP_FLAGS are the flags needed for compilation with OpenMP
        OMP_FLAGS="-fopenmp -fcray-pointer"
        # OMP_LD are the flags needed for linking with OpenMP
        OMP_LD="-fopenmp"
    elif [ "$compiler" = "ifort" ] ; then
        MPI_FLAGS=""
        OMP_FLAGS="-openmp"
        OMP_LD="-openmp"
    else # pgf90
        MPI_FLAGS=""
        OMP_FLAGS="-mp"
        OMP_LD="-mp"
    fi
fi

#####################################################################
# Test for old gfortran compilers
# If the compiler is too old (older than 4.3.x) we test if the
# temporary gfortran44 patch is available on the computer in which
# case the compiler is changed from gfortran to gfortran44
# Must be aware than parallelism can not be activated in this case
#####################################################################

if [ "$compiler" = "gfortran" ] ; then
    gfortran=gfortran
    gfortranv=`gfortran --version | \
   head -1 | awk ' { print $NF } ' | awk -F. ' { print $1 * 10 + $2 } '`
    if [ $gfortranv -le 43 ] ; then
        echo ERROR : Your gfortran compiler is too old
        echo 'Please choose a new one (ifort) and change the line'
        echo compiler=xxx
        echo in the install_lmdz.sh script and rerun it
        if [ `which gfortran44 | wc -w` -ne 0 ] ; then
            gfortran=gfortran44
        else
            echo gfotran trop vieux ; exit
        fi
    fi
    compiler=$gfortran
fi
#####################################################################

## if also compiling XIOS, parallel must be mpi_omp
if [ "$with_xios" = "y" -a "$parallel" != "mpi_omp" ] ; then
    echo "Error, you must set -parallel mpi_omp if you want XIOS"
    exit
fi

if [ "$with_xios" = "y" ] ; then
    opt_makelmdz_xios="-io xios"
fi

if [ "$cosp" = "v2" -a "$with_xios" = "n" ] ; then
    echo "Error, Cospv2 cannot run without Xios"
    exit
fi

echo '################################################################'
echo  Choix des options de compilation
echo '################################################################'

export FC=$compiler
export F90=$compiler
export F77=$compiler
export CPPFLAGS=
OPTIMNC=$OPTIM
BASE_LD="$OPT_GPROF"
OPTPREC="$OPT_GPROF"
ARFLAGS="rs"
if [ "`lsb_release -i -s`" = "Ubuntu" ] ; then
    if [ "`lsb_release -r -s | cut -d. -f1`" -ge 16 ] ; then
            ARFLAGS="rU"
    fi
fi

if [ "$compiler" = "$gfortran" ] ; then
   OPTIM="-O3 $allow_arg_mismatch"
   OPTDEB="-g3 -Wall -fbounds-check -ffpe-trap=invalid,zero,overflow -O0 -fstack-protector-all -fbacktrace -finit-real=snan  $allow_arg_mismatch"
   OPTDEV="-Wall -fbounds-check  $allow_arg_mismatch"
   fmod='I '
   OPTPREC="$OPTPREC -cpp -ffree-line-length-0"
   if [ $real = r8 ] ; then OPTPREC="$OPTPREC -fdefault-real-8 -DNC_DOUBLE" ; fi
   export F90FLAGS=" -ffree-form $OPTIMNC"
   export FFLAGS=" $OPTIMNC"
   export CC=gcc
   export CXX=g++
   export fpp_flags="-P -C -traditional -ffreestanding"

elif [ $compiler = mpif90 ] ; then
    OPTIM='-O3'
    OPTDEB="-g3 -Wall -fbounds-check -ffpe-trap=invalid,zero,overflow -O0 -fstack-protector-all"
    OPTDEV="-Wall -fbounds-check"
    BASE_LD="$BASE_LD -lblas"
    fmod='I '
    if [ $real = r8 ] ; then
        OPTPREC="$OPTPREC -fdefault-real-8 -DNC_DOUBLE -fcray-pointer"
    fi
    export F90FLAGS=" -ffree-form $OPTIMNC"
    export FFLAGS=" $OPTIMNC"
    export CC=gcc
    export CXX=g++

elif [ $compiler = pgf90 ] ; then
    OPTIM='-O2 -Mipa -Munroll -Mnoframe -Mautoinline -Mcache_align'
    OPTDEB='-g -Mdclchk -Mbounds -Mchkfpstk -Mchkptr -Minform=inform -Mstandard -Ktrap=fp -traceback'
    OPTDEV='-g -Mbounds -Ktrap=fp -traceback'
    fmod='module '
    if [ $real = r8 ] ; then OPTPREC="$OPTPREC -r8 -DNC_DOUBLE" ; fi
    export CPPFLAGS="-DpgiFortran"
    export CC=pgcc
    export CFLAGS="-O2 -Msignextend"
    export CXX=pgCC
    export CXXFLAGS="-O2 -Msignextend"
    export FFLAGS="-O2 $OPTIMNC"
    export F90FLAGS="-O2 $OPTIMNC"
    compile_with_fcm=1

elif [[ $compiler = ifort || $compiler = mpiifort ]] ; then
    OPTIM="-O2 -fp-model strict -ip -align all "
    OPTDEV="-p -g -O2 -traceback -fp-stack-check -ftrapuv -check"
    OPTDEB="-g -no-ftz -traceback -ftrapuv -fp-stack-check -check"
    fmod='module '
    if [ $real = r8 ] ; then OPTPREC="$OPTPREC -real-size 64 -DNC_DOUBLE" ; fi
    export CPP="icc -E"
    export FFLAGS="-O2 -ip -fpic -mcmodel=large"
    export FCFLAGS="-O2 -ip -fpic -mcmodel=large"
    export CC=icc
    export CFLAGS="-O2 -ip -fpic -mcmodel=large"
    export CXX=icpc
    export CXXFLAGS="-O2 -ip -fpic -mcmodel=large"
    export fpp_flags="-P -traditional"
    # Pourquoi forcer la compilation fcm. Marche mieux sans
    #compile_with_fcm=1
else
    echo unexpected compiler $compiler ; exit
fi

OPTIMGCM="$OPTIM $OPTPREC"

hostname=`hostname`

##########################################################################
# If installing on known machines such as Jean-Zay at IDRIS,
# don't check for available software and don't install netcdf
if [ ${hostname:0:5} = jean- ] ; then
    netcdf=0 # no need to recompile netcdf, alreday available
    check_linux=0
    pclinux=0
    ioipsl=0 # no need to recompile ioipsl, already available
    #netcdf="/smplocal/pub/NetCDF/4.1.3"
    compiler="mpiifort"
    fmod='module '
    if [ $real = r8 ] ; then OPTPREC="$OPTPREC -i4 -r8 -DNC_DOUBLE" ; fi
    OPTIM="-auto -align all -O2 -fp-model strict -xHost "
    OPTIMGCM="$OPTIM $OPTPREC"
fi
##########################################################################


mkdir -p $MODEL
echo $MODEL
MODEL=`( cd $MODEL ; pwd )` # to get absolute path, if necessary


if [ "$check_linux" = 1 ] ; then
    echo '################################################################'
    echo   Check if required software is available
    echo '################################################################'

    #### Ehouarn: test if the required shell is available
    #### Maj FH-LF-AS 2021-04 : default=bash ; if bash missing, use ksh
    use_shell="bash" # default
    if [ "`which bash`" = "" ] ; then
        echo "no bash ; we will use ksh"
        use_shell="ksh"
        if [ "`which ksh`" = "" ] ; then
            echo "bash (or ksh) needed!! Install it!"
            exit
        fi
    fi

    for logiciel in wget tar gzip make $compiler gcc cmake m4 c++ ; do
        if [ "`which $logiciel`" = "" ] ; then
            echo You must first install $logiciel on your system
            exit
        fi
    done

    if [ $pclinux = 1 ] ; then
        cd $MODEL
        cat <<eod > tt.f90
print*,'coucou'
end
eod
        $compiler tt.f90 -o a.out
        ./a.out >| tt
        if [ "`cat tt | sed -e 's/ //g' `" != "coucou" ] ; then
            echo problem installing with compiler $compiler ; exit ; fi
        \rm tt a.out tt.f90
    fi
fi

###########################################################################
if [ $getlmdzor = 1 -a ! -d $MODEL/modipsl ] ; then
###########################################################################
   echo '##########################################################'
   echo  Download a slightly modified version of  LMDZ
   echo '##########################################################'
   cd $MODEL
   getlog=`pwd`/get.log
   echo logfile : $getlog
   myget src_archives/$trusting/modipsl.$version.tar.gz >> get.log 2>&1
   echo install_lmdz.sh wget_OK `date`
   gunzip modipsl.$version.tar.gz >> get.log 2>&1
   tar xf modipsl.$version.tar >> get.log 2>&1
   \rm modipsl.$version.tar
fi

###########################################################################
echo Installing Netcdf
###########################################################################

if [ $netcdf = 0 ] ; then
    ncdfdir=/usr

else
    cd $MODEL

    case $compiler in
      gfortran) opt1="-compiler gnu" ; opt2="-CC gcc -FC gfortran -CXX g++" ;;
      ifort)  opt1="-compiler intel" ; opt2="-CC icc -FC ifort -CXX icpc" ;;
      pgf90)  opt1="-compiler pgf90" ; opt2="-CC pgcc -FC pgf90 -CXX pgCC" ;;
      *)      echo "unexpected compiler $compiler" for netcdf ; exit 1
    esac

    case $with_xios in
        n) script_install_netcdf=install_netcdf4_hdf5_seq.bash
           ncdfdir=netcdf4_hdf5_seq
           opt_=$opt1 ;;
        y) script_install_netcdf=install_netcdf4_hdf5.bash
           ncdfdir=netcdf4_hdf5
           opt_="$opt2 -MPI $root_mpi" ;;
        *) echo with_xios=$with_xios, should be n or y ; exit 1
    esac
    if [ $netcdf = 1 ] ; then
       ncdfdir=$MODEL/$ncdfdir
    else
       mkdir -p $netcdf ; ncdfdir=$netcdf/$ncdfdir
    fi
         
    echo Repertoire netcdf $ncdfdir
    if [ ! -d $ncdfdir ] ; then
        netcdflog=`pwd`/netcdf.log
        echo '----------------------------------------------------------'
        echo Compiling the Netcdf library
        echo '----------------------------------------------------------'
        echo log file : $netcdflog
        myget script_install/$script_install_netcdf >> $netcdflog 2>&1
        chmod u=rwx $script_install_netcdf
        ./$script_install_netcdf -prefix $ncdfdir $opt_ >> $netcdflog 2>&1
    fi

    #----------------------------------------------------------------------------
    # LF rajout d'une verrue, pour une raison non encore expliquee,
    # la librairie est parfois rangée dans lib64 et non dans lib
    # par certains compilateurs
    if [ ! -e lib -a -d lib64 ] ; then ln -s lib64 lib; fi
    #----------------------------------------------------------------------------

    echo install_lmdz.sh netcdf_OK `date`

fi

cat >test_netcdf90.f90 <<EOF
use netcdf
print *, "NetCDF library version: ", nf90_inq_libvers()
end
EOF

$compiler -I$ncdfdir/include test_netcdf90.f90 -L$ncdfdir/lib -lnetcdff \
          -lnetcdf -Wl,-rpath=$ncdfdir/lib && ./a.out
    
if (($? == 0))
then
    rm test_netcdf90.f90 a.out
else
    echo "Failed test program using NetCDF-Fortran."
    echo "You can:"
    echo "- check that you have NetCDF-Fortran installed in your system"
    echo "- or specify an installation directory with option -netcdf of" \
         "install_lmdz.sh"
    echo "- or download and compile NetCDF-Fortran with option -netcdf 1 of" \
         "install_lmdz.sh"
    exit 1
fi

#=========================================================================
if [[ ! -f $MODEL/modipsl/lib/libioipsl.a ]]
then
    if [ $ioipsl = 1 ] ; then
        #=====================================================================
        echo OK ioipsl=$ioipsl
        echo '##########################################################'
        echo 'Installing MODIPSL, the installation package manager for the '
        echo 'IPSL models and tools'
        echo '##########################################################'
        echo `date`

        cd $MODEL/modipsl
        \rm -rf lib/*
        cd util
        cp AA_make.gdef AA_make.orig
        F_C="$compiler -c "
        if [ "$compiler" = "$gfortran" -o "$compiler" = "mpif90" ]
        then
            F_C="$compiler -c -cpp "
        fi
        if [ "$compiler" = "pgf90" ] ; then F_C="$compiler -c -Mpreprocess" ; fi
        sed -e 's/^\#.*.g95.*.\#.*.$/\#/' AA_make.gdef > tmp
        sed -e "s:F_L = g95:F_L = $compiler:" \
            -e "s:F_C = g95 -c -cpp:F_C = $F_C": \
            -e 's/g95.*.w_w.*.(F_D)/g95      w_w = '"$OPTIMGCM"'/' \
            -e 's:g95.*.NCDF_INC.*.$:g95      NCDF_INC= '"$ncdfdir"'/include:' \
            -e 's:g95.*.NCDF_LIB.*.$:g95      NCDF_LIB= -L'"$ncdfdir"'/lib -lnetcdff -lnetcdf:' \
            -e 's:g95      L_O =:g95      L_O = -Wl,-rpath='"$ncdfdir"'/lib:' \
            -e "s:-fmod=:-$fmod:" -e 's/-fno-second-underscore//' \
            -e 's:#-Q- g95      M_K = gmake:#-Q- g95      M_K = make:' \
            tmp >| AA_make.gdef

        if [ $pcmac == 1 ]
        then
            cp AA_make.gdef tmp
            sed -e 's/rpath=/rpath,/g' tmp > AA_make.gdef
        fi


        # We use lines for g95 even for the other compilers to run ins_make
        if [ "$use_shell" = "ksh" ] ; then
            ./ins_make $o_ins_make
        else # bash
            sed -e s:/bin/ksh:/bin/bash:g ins_make > ins_make.bash
            if [ "`grep jeanzay AA_make.gdef`" = "" ] ; then
                # Bidouille pour compiler sur ada des vieux modipsl.tar
                echo 'Warning jean-zay not in AA_make.gdef'
                echo 'Think about updating'
                exit 1
            fi

            chmod u=rwx ins_make.bash
            ./ins_make.bash $o_ins_make
        fi # of if [ "$use_shell" = "ksh" ]

        echo install_lmdz.sh MODIPSL_OK `date`

        cd $MODEL/modipsl/modeles/IOIPSL/src
        ioipsllog=`pwd`/ioipsl.log
        echo '##########################################################'
        echo 'Compiling IOIPSL, the interface library with Netcdf'
        echo '##########################################################'
        echo `date`
        echo log file : $ioipsllog

        if [ "$use_shell" = "bash" ] ; then
            cp Makefile Makefile.ksh
            sed -e s:/bin/ksh:/bin/bash:g Makefile.ksh > Makefile
        fi
        ### if [ "$pclinux" = 1 ] ; then
        # Build IOIPSL modules and library
        $make clean
        $make > $ioipsllog 2>&1
        if [ "$compiler" = "$gfortran" -o "$compiler" = "mpif90" ] ; then
            # copy module files to lib
            cp -f *.mod ../../../lib
        fi
        # Build IOIPSL tools (ie: "rebuild", if present)
	  # For IOIPSLv_2_2_2, "rebuild" files are in IOIPSL/tools
	rebuild_dir=""
        if [ -f $MODEL/modipsl/modeles/IOIPSL/tools/rebuild ] ; then 
            rebuild_dir=$MODEL/modipsl/modeles/IOIPSL/tools
	elif [ -d $MODEL/modipsl/modeles/IOIPSL/rebuild ] ; then
              rebuild_dir=$MODEL/modipsl/modeles/IOIPSL/rebuild
        fi
        if [ $rebuild_dir != "" ] ; then
	    cd $rebuild_dir	
            # adapt Makefile & rebuild script if in bash
            if [ "$use_shell" = "bash" ] ; then
                cp Makefile Makefile.ksh
                sed -e s:/bin/ksh:/bin/bash:g Makefile.ksh > Makefile
                cp rebuild rebuild.ksh
                sed -e 's:/bin/ksh:/bin/bash:g' \
                    -e 's:print -u2:echo:g' \
                    -e 's:print:echo:g' rebuild.ksh > rebuild
            fi
            $make clean
            $make > $ioipsllog 2>&1
        fi
        ### fi # of if [ "$pclinux" = 1 ] which is commented out

    else # of if [ $ioipsl = 1 ]
        if [ ${hostname:0:5} = jean- ] ; then
            cd $MODEL/modipsl
            cd util
            if [ "`grep jeanzay AA_make.gdef`" = "" ] ; then
                echo 'Warning jean-zay not in AA_make.gdef'
                echo 'Think about updating'
                exit 1
            fi
            ./ins_make $o_ins_make
            # Compile IOIPSL on jean-zay
            cd $MODEL/modipsl/modeles/IOIPSL/src
            gmake > ioipsl.log
	    # For IOIPSLv_2_2_2, "rebuild" files are in IOIPSL/tools, so "gmake" in IOIPSL/tools is enough
	    # For IOIPSLv_2_2_5, "rebuild" files are in a separate IOIPSL/rebuild folder , while "tools" only contains "FCM"
	    if [ -f $MODEL/modipsl/modeles/IOIPSL/tools/Makefile ] ; then
              cd $MODEL/modipsl/modeles/IOIPSL/tools
              gmake > ioipsl.log
            fi
            if [ -d $MODEL/modipsl/modeles/IOIPSL/rebuild ] ; then
              cd $MODEL/modipsl/modeles/IOIPSL/rebuild
              gmake > ioipsl.log
            fi

        fi
        echo install_lmdz.sh ioipsl_OK `date`
    fi # of if [ $ioipsl = 1 ]
fi # of if [[ ! -f $MODEL/modipsl/lib/libioipsl.a ]]

#=========================================================================
if [ "$with_xios" = "y" ] ; then
    echo '##########################################################'
    echo 'Compiling XIOS'
    echo '##########################################################'
    cd $MODEL/modipsl/modeles
    xioslog=`pwd`/XIOS/xios.log
    #wget http://www.lmd.jussieu.fr/~lmdz/Distrib/install_xios.bash
    myget script_install/install_xios.bash
    chmod u=rwx install_xios.bash
# following will be recalculated later on once LMDZ is updated
#    mysvn=`svnversion LMDZ | egrep -o "[0-9]+" 2>/dev/null`
    mysvn=`grep 'Revision: [0-9]' $MODEL/Read*.md | awk ' { print $2 } ' 2>/dev/null`
    if [ "$svn" != "" ] ; then mysvn=$svn ; fi 
    echo mysvn $mysvn

    if [ ${hostname:0:5} = jean- ] ; then
	if [ $mysvn -ge 4619 ] ; then 
          svn co http://forge.ipsl.fr/ioserver/svn/XIOS2/branches/xios-2.6 \
            XIOS
	else
          svn co http://forge.ipsl.fr/ioserver/svn/XIOS2/branches/xios-2.5 \
            XIOS
        fi
        cd XIOS/arch
        svn update
        cd ..
        echo "Compiling XIOS, start" `date` \
        echo "log file: $xioslog"
        #./make_xios --prod --arch $arch --job 4 > xios.log 2>&1
	cat > compile_xios.sh <<EOD
./make_xios --prod --arch X64_JEANZAY --full --job 4 > xios.log 2>&1
EOD
srun --pty --ntasks=1 --cpus-per-task=20 --hint=nomultithread -t 00:30:00 \
 --account=gzi@cpu --qos=qos_cpu-dev bash ./compile_xios.sh

    else
        ./install_xios.bash -prefix $MODEL/modipsl/modeles \
                            -netcdf ${ncdfdir} -hdf5 ${ncdfdir} \
                            -MPI $root_mpi -arch $arch > xios.log 2>&1
    fi # of case Jean-Zay
    if [ -f XIOS/lib/libxios.a ] ; then
        echo "XIOS library successfully generated"
        echo install_lmdz.sh XIOS_OK `date`
    fi
fi

#============================================================================
veget_version=false
if [ "$veget" != 'NONE' ] ; then
    cd $MODEL/modipsl/modeles/ORCHIDEE
    set +e ; svn upgrade ; set -e
    if [ "$veget" = "CMIP6" ] ; then
        veget_version=orchidee2.0
        orchidee_rev=6592
    else # specific orchidee revision newer than CMIP6, on 2_1 or 2_2 branches
        veget_version=orchidee2.1
        orchidee_rev=$veget
        if [ $veget -lt 4465 ] ; then
            echo 'Stopping, ORCHIDEE version too old, script needs work on ' \
                 'the CPP flags to pass to makelmdz'
            exit 1
        fi
        set +e
        # which branch is my version on?
        orcbranch=`svn log -v -q svn://forge.ipsl.fr/orchidee/ -r $veget |grep ORCHIDEE |head -1| sed -e 's:ORCHIDEE/.*$:ORCHIDEE:' | awk '{print $2}'`
        # switch to that branch
        echo IF YOU INSTALL ORCHIDEE THE VERY FIRST TIME, ASK for PASSWORD at \
             orchidee-help@listes.ipsl.fr
        svn switch -r $veget --accept theirs-full \
            svn://forge.ipsl.fr/orchidee/$orcbranch
        svn log -r $veget | grep  $veget
        if [  $? -gt 0 ] ; then
            echo 'Cannot update ORCHIDEE as not on the right branch for ' \
                 'ORCHIDEE'
            exit
        fi
        set -e
        set +e ; svn update -r $veget ; set -e
    fi
    # Correctif suite debug Jean-Zay
    sed -i -e 's/9010  FORMAT(A52,F17.14)/9010  FORMAT(A52,F20.14)/' \
        src_stomate/stomate.f90
    opt_orc="-prod" ; if [ "$optim" = "-debug" ] ; then opt_orc="-debug" ; fi

    orchideelog=`pwd`/orchidee.log
    echo '########################################################'
    echo 'Compiling ORCHIDEE, the continental surface model '
    echo '########################################################'
    echo Start of the first compilation of orchidee, in sequential mode: `date`
    echo log file : $orchideelog

    export ORCHPATH=`pwd`
    xios_orchid="-noxios"
    if [ "$with_xios" = "y" ] ; then
        xios_orchid="-xios"
    fi
    if [ -d tools ] ; then
        ###################################################################
        # Pour les experts qui voudraient changer de version d'orchidee.
        # Attention : necessite d'avoir le password pour orchidee

        # Correctif suite debug Jean-Zay
        if [ -f src_global/time.f90 ] ; then
            sed -i -e 's/CALL tlen2itau/\!CALL tlen2itau/' src_global/time.f90
        fi
        ###################################################################
        if [ "$veget_version" == "false" ] ; then
            veget_version=orchidee2.0
        fi
        cd arch
        sed -e s:"%COMPILER        .*.$":"%COMPILER            $compiler":1 \
            -e s:"%LINK            .*.$":"%LINK                $compiler":1 \
            -e s:"%FPP_FLAGS       .*.$":"%FPP_FLAGS           $fpp_flags":1 \
            -e s:"%PROD_FFLAGS     .*.$":"%PROD_FFLAGS         $OPTIM":1 \
            -e s:"%DEV_FFLAGS      .*.$":"%DEV_FFLAGS          $OPTDEV":1 \
            -e s:"%DEBUG_FFLAGS    .*.$":"%DEBUG_FFLAGS        $OPTDEB":1 \
            -e s:"%BASE_FFLAGS     .*.$":"%BASE_FFLAGS         $OPTPREC":1 \
            -e s:"%BASE_LD         .*.$":"%BASE_LD             $BASE_LD":1 \
            -e s:"%ARFLAGS         .*.$":"%ARFLAGS             $ARFLAGS":1 \
            arch-gfortran.fcm > arch-local.fcm
        echo "NETCDF_LIBDIR=\"-L${ncdfdir}/lib -lnetcdff -lnetcdf\"" \
             > arch-local.path
        echo "NETCDF_INCDIR=${ncdfdir}/include" >> arch-local.path
        echo "IOIPSL_INCDIR=$ORCHPATH/../../lib" >> arch-local.path
        echo "IOIPSL_LIBDIR=$ORCHPATH/../../lib" >> arch-local.path
        echo 'XIOS_INCDIR=${ORCHDIR}/../XIOS/inc' >> arch-local.path
        echo 'XIOS_LIBDIR="${ORCHDIR}/../XIOS/lib -lxios"' >> arch-local.path
        cd ../

        echo ./makeorchidee_fcm -j $xios_orchid $opt_orc -parallel none \
             -arch $arch
        ./makeorchidee_fcm -j 8 $xios_orchid $opt_orc -parallel none \
                           -arch $arch > $orchideelog 2>&1
        pwd
    else # of "if [ -d tools ]"
        if [ -d src_parallel ] ; then
            liste_src="parallel parameters global stomate sechiba driver"
            if [ "$veget_version" == "false" ] ; then
                veget_version=orchidee2.0
            fi
        fi
        for d in $liste_src ; do
            src_d=src_$d
            echo src_d $src_d
            echo ls ; ls
            if [ ! -d $src_d ] ; then
                echo Problem orchidee : no $src_d ; exit
            fi
            cd $src_d ; \rm -f *.mod make ; $make clean
            $make > $orchideelog 2>&1
            if [ "$compiler" = "$gfortran" -o "$compiler" = "mpif90" ] ; then
                cp -f *.mod ../../../lib
            fi
            cd ..
        done
    fi # of "if [ -d tools ]"
    echo install_lmdz.sh orchidee_compil_seq_OK `date`
fi # of if [ "$veget" != 'NONE' ]


#============================================================================
# Ehouarn: the directory name LMDZ* depends on version/tar file...
if [ -d $MODEL/modipsl/modeles/LMD* ] ; then
    echo '###############################################################'
    echo 'Preparing LMDZ compilation : arch file, svn switch if needed...'
    echo '###############################################################'
    cd $MODEL/modipsl/modeles/LMD*
    LMDZPATH=`pwd`
else
    echo "ERROR: No LMD* directory !!!"
    exit
fi

###########################################################
# For those who want to use fcm to compile via :
#  makelmdz_fcm -arch local .....
############################################################



cd $MODEL/modipsl/modeles/LMDZ*
lmdzlog=`pwd`/lmdz.log

##################################################################
# Possibly update LMDZ if a specific svn release is requested
##################################################################

set +e ; svn upgrade ; set -e

if [ "$svn" = "last" ] ; then svnopt="" ; else svnopt="-r $svn" ; fi
if [ "$svn" != "" ] ; then
    set +e ; svn info | grep -q 'https:'
    if [ $? = 0 ] ; then
        svn switch --relocate https://svn.lmd.jussieu.fr/LMDZ \
            http://svn.lmd.jussieu.fr/LMDZ
    fi
    svn update $svnopt
    set -e
fi

#---------------------------------------------------------------------
# Retrieve the final svn release number, and adjust compilation
# options accordingly
# If svn not available, will use the svn writen in $MODEL/Readm*md
# For old version it assumes that it is before 4185 (the version
# for which the test was introduced
#---------------------------------------------------------------------

set +e ; mysvn=`svnversion . | egrep -o "[0-9]+" 2>/dev/null` ; set -e
if [ "$mysvn" = "" ] ; then mysvn=`grep 'Revision: [0-9]' $MODEL/Read*.md | awk ' { print $2 } ' 2>/dev/null` ; fi
if [ "$mysvn" = "" ] ; then mysvn=4190 ; fi

if [[ "$pclinux" = "1" && ! -f arch/arch-local.path ]] ; then

    # create local 'arch' files (if on Linux PC):
    cd arch
    # arch-local.path file
    # test for version as arch.pth file changed format with rev 4426
    if [ "$mysvn" -gt 4425 ] ; then
      echo "NETCDF_LIBDIR=\"-L${ncdfdir}/lib \"" > arch-local.path
      echo "NETCDF_LIB=\"-lnetcdff -lnetcdf\"" >> arch-local.path
      echo "NETCDF_INCDIR=-I${ncdfdir}/include" >> arch-local.path
      echo 'NETCDF95_INCDIR=-I$LMDGCM/../../include' >> arch-local.path
      echo 'NETCDF95_LIBDIR=-L$LMDGCM/../../lib' >> arch-local.path
      echo 'NETCDF95_LIB=-lnetcdf95' >> arch-local.path
      echo 'IOIPSL_INCDIR=-I$LMDGCM/../../lib' >> arch-local.path
      echo 'IOIPSL_LIBDIR=-L$LMDGCM/../../lib' >> arch-local.path
      echo 'IOIPSL_LIB=-lioipsl' >> arch-local.path
      echo 'XIOS_INCDIR=-I$LMDGCM/../XIOS/inc' >> arch-local.path
      echo 'XIOS_LIBDIR=-L$LMDGCM/../XIOS/lib' >> arch-local.path
      echo "XIOS_LIB=\"-lxios -lstdc++\"" >> arch-local.path
      echo 'ORCH_INCDIR=-I$LMDGCM/../../lib' >> arch-local.path
      echo 'ORCH_LIBDIR=-L$LMDGCM/../../lib' >> arch-local.path
    else
      echo "NETCDF_LIBDIR=\"-L${ncdfdir}/lib -lnetcdff -lnetcdf\"" \
         > arch-local.path
      echo "NETCDF_INCDIR=-I${ncdfdir}/include" >> arch-local.path
      echo 'NETCDF95_INCDIR=$LMDGCM/../../include' >> arch-local.path
      echo 'NETCDF95_LIBDIR=$LMDGCM/../../lib' >> arch-local.path
      echo 'IOIPSL_INCDIR=$LMDGCM/../../lib' >> arch-local.path
      echo 'IOIPSL_LIBDIR=$LMDGCM/../../lib' >> arch-local.path
      echo 'XIOS_INCDIR=$LMDGCM/../XIOS/inc' >> arch-local.path
      echo 'XIOS_LIBDIR=$LMDGCM/../XIOS/lib' >> arch-local.path
      echo 'ORCH_INCDIR=$LMDGCM/../../lib' >> arch-local.path
      echo 'ORCH_LIBDIR=$LMDGCM/../../lib' >> arch-local.path
    fi 

    if [ $pcmac == 1 ] ; then
        BASE_LD="$BASE_LD -Wl,-rpath,${ncdfdir}/lib"
    else
        BASE_LD="$BASE_LD -Wl,-rpath=${ncdfdir}/lib"
    fi
    # Arch-local.fcm file (adapted from arch-linux-32bit.fcm)

    if [ $real = r8 ] ; then FPP_DEF=NC_DOUBLE ; else FPP_DEF="" ; fi
    sed -e s:"%COMPILER        .*.$":"%COMPILER            $compiler":1 \
        -e s:"%LINK            .*.$":"%LINK                $compiler":1 \
        -e s:"%PROD_FFLAGS     .*.$":"%PROD_FFLAGS         $OPTIM":1 \
        -e s:"%DEV_FFLAGS      .*.$":"%DEV_FFLAGS          $OPTDEV":1 \
        -e s:"%DEBUG_FFLAGS    .*.$":"%DEBUG_FFLAGS        $OPTDEB":1 \
        -e s:"%BASE_FFLAGS     .*.$":"%BASE_FFLAGS         $OPTPREC":1 \
        -e s:"%FPP_DEF         .*.$":"%FPP_DEF             $FPP_DEF":1 \
        -e s:"%BASE_LD         .*.$":"%BASE_LD             $BASE_LD":1 \
        -e s:"%ARFLAGS         .*.$":"%ARFLAGS             $ARFLAGS":1 \
        arch-linux-32bit.fcm > arch-local.fcm

    cd ..
    ### Adapt "bld.cfg" (add the shell):
    #whereisthatshell=$(which ${use_shell})
    #echo "bld::tool::SHELL   $whereisthatshell" >> bld.cfg

fi # of if [ "$pclinux" = 1 ]
#---------------------------------------------------------------------
# Option de compilation du rayonnement : depend de $mysvn ><= r4185
#---------------------------------------------------------------------
opt_rad=""

case $rad in
    oldrad) iflag_rrtm=0 ; NSW=2 ; opt_rad="" ;;
    rrtm)   iflag_rrtm=1 ; NSW=6
            if [ $mysvn -le 4185 ] ; then
                opt_rad="-rrtm true"
            else
                opt_rad="-rad rrtm"
            fi ;;
    ecrad)  iflag_rrtm=2 ; NSW=6 ; opt_rad="-rad ecrad" ;;
    *) echo Only oldrad rrtm ecrad for rad option ; exit
esac

if [ $mysvn -le 4185 -a $rad = "ecrad" ] ; then
    echo "ecrad only available for LMDZ rev starting with 4186 " ; exit
fi

##################################################################


if [[ ! -f libf/misc/netcdf95.F90 &&  ! -d $MODEL/NetCDF95-0.3 ]]
then
    cd $MODEL
    myget src_archives/netcdf/NetCDF95-0.3.tar.gz
    tar -xf NetCDF95-0.3.tar.gz
    rm NetCDF95-0.3.tar.gz
    cd NetCDF95-0.3
    mkdir build
    cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=$ncdfdir \
          -DCMAKE_INSTALL_PREFIX=$MODEL/modipsl
    make install
    cd $MODEL/modipsl/modeles/LMDZ*
fi

echo '##################################################################'
echo "Preparing script compile.sh for LMDZ compilation"
echo "It will only be run automatically if bench=1/tuto"
echo Here bench=$bench
echo '##################################################################'

if [ "$env_file" != "" ] ; then
    mv arch/arch-${arch}.env arch/arch-${arch}.orig
    \cp -f $env_file arch/arch-${arch}.env
fi

if [ $compile_with_fcm = 1 ] ; then
    makelmdz="makelmdz_fcm $optim -arch $arch -j 8 "
else
    makelmdz="makelmdz $optim -arch $arch"
fi

# sequential compilation
if [ "$sequential" = 1 ] ; then
    echo Sequential compilation command, saved in compile.sh:
    echo "./$makelmdz $optim $OPT_MAKELMDZ $optim $opt_rad $opt_cosp " \
         "-d ${grid_resolution} -v $veget_version gcm "
    echo "./$makelmdz $optim $OPT_MAKELMDZ $optim $opt_rad $opt_cosp " \
         "-d ${grid_resolution} -v $veget_version gcm " > compile.sh
    chmod +x ./compile.sh
    if [ $bench = 1 ] ; then
        echo install_lmdz.sh start_lmdz_seq_compilation `date`
        echo log file: $lmdzlog
        ./compile.sh > $lmdzlog 2>&1
        echo install_lmdz.sh end_lmdz_seq_compilation `date`
    fi
fi # fin sequential

# compiling in parallel mode
if [ $parallel != "none" ] ; then
    echo '##########################################################'
    echo ' Parallel compile '
    echo '##########################################################'
    echo "(after saving the sequential libs and binaries)"
    cd $MODEL/modipsl
    tar cf sequential.tar bin/ lib/
    #
    # Orchidee
    #
    cd $ORCHPATH
    if [ -d src_parallel -a $veget != 'NONE' ] ; then
        cd arch
        sed  \
            -e s:"%COMPILER.*.$":"%COMPILER            $par_comp":1 \
            -e s:"%LINK.*.$":"%LINK                $par_comp":1 \
            -e s:"%MPI_FFLAG.*.$":"%MPI_FFLAGS          $MPI_FLAGS":1 \
            -e s:"%OMP_FFLAG.*.$":"%OMP_FFLAGS          $OMP_FLAGS":1 \
            -e s:"%MPI_LD.*.$":"%MPI_LD              $MPI_LD":1 \
            -e s:"%OMP_LD.*.$":"%OMP_LD              $OMP_LD":1 \
            arch-local.fcm > tmp.fcm

        mv tmp.fcm arch-local.fcm
        cd ../
        echo Compiling ORCHIDEE in parallel mode `date`
        echo logfile $orchideelog
        echo "NOTE : to recompile it when necessary, use ./compile_orc.sh " \
             "in modipsl/modeles/ORCHIDEE"
        echo ./makeorchidee_fcm -j 8 -clean $xios_orchid $opt_orc \
             -parallel $parallel -arch $arch > compile_orc.sh
        echo ./makeorchidee_fcm -j 8 $xios_orchid $opt_orc \
             -parallel $parallel -arch $arch >> compile_orc.sh
        echo echo Now you must also recompile LMDZ, by running ./compile.sh \
             in modeles/LMDZ >> compile_orc.sh
        chmod u+x compile_orc.sh
        ./makeorchidee_fcm -j 8 -clean $xios_orchid $opt_orc \
                           -parallel $parallel -arch $arch > $orchideelog 2>&1
        ./makeorchidee_fcm -j 8 $xios_orchid $opt_orc -parallel $parallel \
                           -arch $arch >> $orchideelog 2>&1
        echo End of ORCHIDEE compilation in parallel mode `date`
    elif [ $veget != 'NONE' ] ; then
        echo '##########################################################'
        echo ' Orchidee version too old                                 '
        echo ' Please update to new version                             '
        echo '##########################################################'
        exit
    fi # of [ -d src_parallel -a $veget != 'NONE' ]

    # LMDZ
    cd $LMDZPATH
    if [ $arch = local ] ; then
        cd arch
        sed -e s:"%COMPILER.*.$":"%COMPILER            $par_comp":1 \
            -e s:"%LINK.*.$":"%LINK                $par_comp":1 \
            -e s:"%MPI_FFLAG.*.$":"%MPI_FFLAGS          $MPI_FLAGS":1 \
            -e s:"%OMP_FFLAG.*.$":"%OMP_FFLAGS          $OMP_FLAGS":1 \
            -e s:"%ARFLAGS.*.$":"%ARFLAGS          $ARFLAGS":1 \
            -e s@"%BASE_LD.*.$"@"%BASE_LD             -Wl,-rpath=${root_mpi}/lib:${ncdfdir}/lib"@1 \
            -e s:"%MPI_LD.*.$":"%MPI_LD              $MPI_LD":1 \
            -e s:"%OMP_LD.*.$":"%OMP_LD              $OMP_LD":1 \
            arch-local.fcm > tmp.fcm
        mv tmp.fcm arch-local.fcm
        cd ../
    fi
    rm -f compile.sh
    echo resol=${grid_resolution} >> compile.sh
    if [ ${hostname:0:5} = jean- -a "$cosp" = "v2" ] ; then

        echo LMDZ compilation command in parallel mode, saved in compile.sh, \
             is :
        echo "(ATTENTION le probleme de cospv2 sur jean-zay en mode prod " \
             "n est pas corrige ! )"
        # ATTENTION le probleme de cospv2 sur jean-zay en mode prod n
        # est pas corrige
        echo ./$makelmdz -dev $optim $OPT_MAKELMDZ $opt_rad $opt_cosp \
             $opt_makelmdz_xios -d \$resol -v $veget_version -mem \
             -parallel $parallel gcm >> compile.sh
        echo ./$makelmdz -dev $optim $OPT_MAKELMDZ $opt_rad $opt_cosp \
             $opt_makelmdz_xios -d \$resol -v $veget_version -mem \
             -parallel $parallel gcm
    else
        echo ./$makelmdz $optim $OPT_MAKELMDZ $opt_rad $opt_cosp \
             $opt_makelmdz_xios -d \$resol -v $veget_version -mem \
             -parallel $parallel gcm >> compile.sh
        echo ./$makelmdz $optim $OPT_MAKELMDZ $opt_rad $opt_cosp \
             $opt_makelmdz_xios -d \$resol -v $veget_version -mem \
             -parallel $parallel gcm
    fi
    chmod +x ./compile.sh

    if [ $bench = 1 ] ; then
        echo Compiling LMDZ in parallel mode `date`,  LMDZ log file: $lmdzlog
        ./compile.sh > $lmdzlog 2>&1
    fi

fi # of if [ $parallel != "none" ]


##################################################################
# Verification du succes de la compilation
##################################################################

# Recherche de l'executable dont le nom a change au fil du temps ...
# suffix contains radiative option starting with revision 4186
if [ $mysvn -ge 4186 ] ; then suff_exe=_${rad}${suff_exe} ; fi
gcm=""

for exe in gcm.e bin/gcm_${grid_resolution}_phylmd${suff_exe}${suff_orc}.e
do
    if [ -f $exe ] ; then gcm=$exe ; fi
done

if [ "$gcm" = "" ] ; then
    if [ $bench = 1 ] ; then
        echo 'Compilation failed !! Cannot run the benchmark;'
        exit
    else
        echo 'Compilation not done (only done when bench=1)'
    fi
else
    echo '##########################################################'
    echo 'Compilation successfull !! ' `date`
    echo '##########################################################'
    echo The executable is $gcm
fi

##################################################################
# Below, we run a benchmark if bench=1 or tuto
##################################################################

if [ $bench = tuto ] ; then
    myget Training/tutorial.tar ; tar xf tutorial.tar ; cd TUTORIAL
    ./init.sh

elif [[ $bench = 1 && ! -d BENCH${grid_resolution} ]] ; then
    # TOUTE CETTE SECTION DEVRAIT DISPARAITRE POUR UNE COMMANDE
    # OU DES BENCHS PAR MOTS CLES COMME tuto

    echo '##########################################################'
    echo ' Running a test run '
    echo '##########################################################'

    \rm -rf BENCH${grid_resolution}
    bench=bench_lmdz_${grid_resolution}
    echo install_lmdz.sh before bench download  `date`
    #wget http://www.lmd.jussieu.fr/~lmdz/Distrib/$bench.tar.gz
    myget 3DBenchs/$bench.tar.gz
    echo install_lmdz.sh after bench download  `date`
    tar xf $bench.tar.gz

    if [ "$cosp" = "v1" -o "$cosp" = "v2" ] ; then
        cd BENCH${grid_resolution}
        # copier les fichiers namelist input et output our COSP
        cp ../DefLists/cosp*_input_nl.txt .
        cp ../DefLists/cosp*_output_nl.txt .
        # Activer la cles ok_cosp pour tourner avec COSP
        sed -e 's@ok_cosp=n@ok_cosp=y@' config.def > tmp
        \mv -f tmp config.def
        cd ..
    fi

    if [ -n "$physiq" ]; then
        cd BENCH${grid_resolution}
        if [ -f physiq.def_${physiq} ]; then
            cp physiq.def_${physiq} physiq.def
            echo using physiq.def_${physiq}
        else
            echo using standard physiq.def
        fi
        cd ..
    else
        echo using standard physiq.def
    fi

    if [ "$with_xios" = "y" ] ; then
        cd BENCH${grid_resolution}
        cp ../DefLists/iodef.xml .
        cp ../DefLists/context_lmdz.xml .
        cp ../DefLists/field_def_lmdz.xml .
        # A raffiner par la suite
        echo A FAIRE : Copier les *xml en fonction de l option cosp
        cp ../DefLists/field_def_cosp*.xml .
        cp ../DefLists/file_def_hist*xml .
        # adapt iodef.xml to use attached mode
        sed -e 's@"using_server" type="bool">true@"using_server" type="bool">false@' \
            iodef.xml > tmp
        \mv -f tmp iodef.xml

        # and convert all the enabled="_AUTO_" (for libIGCM) to enabled=.FALSE.
        # except for histday
        for histfile in file_def_hist*xml
        do
            if [ "$histfile" = "file_def_histday_lmdz.xml" ] ; then
                sed -e 's@enabled="_AUTO_"@type="one_file" enabled=".TRUE."@' \
                    $histfile > tmp
                \mv -f tmp $histfile
                sed -e 's@output_level="_AUTO_"@output_level="5"@' $histfile \
                    > tmp
                \mv -f tmp $histfile
                sed -e 's@compression_level="2"@compression_level="0"@' \
                    $histfile > tmp
                \mv -f tmp $histfile
            else
                sed -e 's@enabled="_AUTO_"@type="one_file" enabled=".FALSE."@' \
                    $histfile > tmp
                \mv -f tmp $histfile
            fi
        done
        # and add option "ok_all_xml=y" in config.def
        echo "### XIOS outputs" >> config.def
        echo 'ok_all_xml=.true.' >> config.def

        #activer les sorties pour Cosp
        if [ "$cosp" = "v1" ] ; then
            sed -i'' -e 's@enabled=".FALSE."@enabled=".TRUE."@' \
                     -e 's@output_level="_AUTO_"@output_level="5"@' \
                     -e 's@compression_level="2"@compression_level="0"@' \
                     file_def_histdayCOSP_lmdz.xml
        fi
        if [ "$cosp" = "v2" ] ; then
            sed -e 's@compression_level="2"@compression_level="0"@' file_def_histdayCOSPv2_lmdz.xml
            for type_ in hf day mth ; do
                file=file_def_hist${type_}COSP
                sed -i'' -e 's@src="./'${file}'_lmdz.xml"@src="./'${file}'v2_lmdz.xml"@' context_lmdz.xml
            done
            sed -i '' -e 's@field_def_cosp1.xml@field_def_cospv2.xml@' field_def_lmdz.xml
        fi

        cd ..
    fi

    # Cas Bensh avec ecrad
    if [ "$rad" = "ecrad" ] ; then
        cd BENCH${grid_resolution}
        cp  ../DefLists/namelist_ecrad .
        cp -r ../libf/phylmd/ecrad/data .
        cd ..
    fi

    # Adjusting bench physiq.def to radiative code chosen
    cd BENCH${grid_resolution}
    sed -e 's/iflag_rrtm=.*.$/iflag_rrtm='$iflag_rrtm'/' \
        -e 's/NSW=.*.$/NSW='$NSW'/' physiq.def > tmpdef
    \mv tmpdef physiq.def
    cd ..

    cp $gcm BENCH${grid_resolution}/gcm.e

    cd BENCH${grid_resolution}
    # On cree le fichier bench.sh au besoin
    # Dans le cas 48x36x39 le bench.sh existe deja en parallele

    if [ "$grid_resolution" = "48x36x39" ] ; then
        echo On ne touche pas au bench.sh
        # But we have to adapt "run_local.sh" for $mpirun
        sed -e "s@mpirun@$mpirun@g" run_local.sh > tmp
        mv -f tmp run_local.sh
        chmod u=rwx run_local.sh
    elif [ "${parallel:0:3}" = "mpi" ] ; then
        # Lancement avec deux procs mpi et 2 openMP
        echo "export OMP_STACKSIZE=800M" > bench.sh
        if [ "${parallel:4:3}" = "omp" ] ; then
            echo "export OMP_NUM_THREADS=2" >> bench.sh
        fi
        if [ "$cosp" = "v1" -o "$cosp" = "v2" ] ; then
            if [ ${hostname:0:5} = jean- ] ; then
                   chmod +x ../arch.env
                ../arch.env        
                echo "ulimit -s 2000000" >> bench.sh
            else
                echo "ulimit -s 200000" >> bench.sh
            fi        
        else
            echo "ulimit -s unlimited" >> bench.sh
        fi
        if [ ${hostname:0:5} = jean- ] ; then
            . ../arch/arch-${arch}.env
            echo "srun -n 2 -A $idris_acct@cpu gcm.e > listing  2>&1" \
                 >> bench.sh
        else
            echo "$mpirun -np 2 gcm.e > listing  2>&1" >> bench.sh
        fi
        # Add rebuild, using reb.sh if it is there
        echo 'if [ -f reb.sh ] ; then' >> bench.sh
        echo '  ./reb.sh histday ; ./reb.sh histmth ; ./reb.sh histhf ; ' \
             './reb.sh histins ; ./reb.sh stomate_history ; ' \
             './reb.sh sechiba_history ; ./reb.sh sechiba_out_2 ' >> bench.sh
        echo 'fi' >> bench.sh
    else
        echo "./gcm.e > listing  2>&1" > bench.sh
    fi
    # Getting orchidee stuff
    if [ $veget == 'CMIP6' ] ; then
        #echo 'myget 3DBenchs/BENCHorch11.tar.gz'
        #myget 3DBenchs/BENCHorch11.tar.gz
        #tar xvzf BENCHorch11.tar.gz
        echo 'myget 3DBenchs/BENCHCMIP6.tar.gz'
        myget 3DBenchs/BENCHCMIP6.tar.gz
        tar xvzf BENCHCMIP6.tar.gz
        sed -e "s:VEGET=n:VEGET=y:" config.def > tmp
        mv -f tmp config.def
        if [ "$with_xios" = "y" ] ; then
            cp ../../ORCHIDEE/src_xml/context_orchidee.xml .
            echo '<context id="orchidee" src="./context_orchidee.xml"/>' \
                 > add.tmp
            cp ../../ORCHIDEE/src_xml/field_def_orchidee.xml .
            cp ../../ORCHIDEE/src_xml/file_def_orchidee.xml .
            cp ../../ORCHIDEE/src_xml/file_def_input_orchidee.xml .
            if [ -f ../../ORCHIDEE/src_xml/context_input_orchidee.xml ] ; then
                   cp ../../ORCHIDEE/src_xml/context_input_orchidee.xml .
                   echo '<context id="orchidee" ' \
                     'src="./context_input_orchidee.xml"/>' >> add.tmp
            fi
            sed -e '/id="LMDZ"/r add.tmp' iodef.xml > tmp
            mv tmp iodef.xml
            sed -e'{/sechiba1/ s/enabled="_AUTO_"/type="one_file" enabled=".TRUE."/}' \
                file_def_orchidee.xml > tmp
            \mv -f tmp file_def_orchidee.xml
            sed -e 's@enabled="_AUTO_"@type="one_file" enabled=".FALSE."@' \
                file_def_orchidee.xml > tmp
            \mv -f tmp file_def_orchidee.xml
            sed -e 's@output_level="_AUTO_"@output_level="1"@' \
                file_def_orchidee.xml > tmp
            \mv -f tmp file_def_orchidee.xml
            sed -e 's@output_freq="_AUTO_"@output_freq="1d"@' \
                file_def_orchidee.xml > tmp
            \mv -f tmp file_def_orchidee.xml
            sed -e 's@compression_level="4"@compression_level="0"@' \
                file_def_orchidee.xml > tmp
            \mv -f tmp file_def_orchidee.xml
            sed -e 's@XIOS_ORCHIDEE_OK = n@XIOS_ORCHIDEE_OK = y@' \
                orchidee.def > tmp
            \mv -f tmp orchidee.def
        fi
    fi

    if [[ -f ../arch.env ]]
    then
        source ../arch.env
    fi

    echo EXECUTION DU BENCH
    set +e
    date ; ./bench.sh > out.bench 2>&1 ; date
    set -e
    tail listing


    echo '##########################################################'
    echo 'Simulation finished in' `pwd`
    echo 'You have compiled with:'
    cat ../compile.sh
    if [ $parallel = "none" ] ; then
        echo 'You may re-run it with : cd ' `pwd` ' ; gcm.e'
        echo 'or ./bench.sh'
    else
        echo 'You may re-run it with : '
        echo 'cd ' `pwd` '; ./bench.sh'
        #  echo 'ulimit -s unlimited'
        #  echo 'export OMP_NUM_THREADS=2'
        #  echo 'export OMP_STACKSIZE=800M'
        #  echo "$mpirun -np 2 gcm.e "
    fi
    echo '##########################################################'

fi # bench


#################################################################
# Installation eventuelle du 1D
#################################################################

if [ $SCM = 1 ] ; then
    cd $MODEL
    myget 1D/1D.tar.gz
    tar xf 1D.tar.gz
    cd 1D
    if [ $rad = oldrad ] ; then
        sed -i'' -e 's/^rad=.*$/rad=oldrad/' run.sh
        sed -i'' -e 's/^rad=.*$/rad=oldrad/' bin/compile
    fi
    if [ $rad = ecrad ] ; then
        sed -i'' -e 's/^rad=.*$/rad=ecrad/' run.sh
        sed -i'' -e 's/^rad=.*$/rad=ecrad/' bin/compile
    fi
    echo Running 1D/run.sh, log in `pwd`/run1d.log
    ./run.sh > `pwd`/run1d.log 2>&1
fi


#################################################################
# sauvegarde des options veget pour utilisation eventuelle tutorial_prod
#################################################################
cd $MODEL/modipsl/modeles
#echo surface_env file created in $MODEL
echo 'veget='$veget > surface_env
#opt_veget="-v $veget_version"
#echo 'opt_veget="'$opt_veget\" >> surface_env
echo 'opt_veget="'-v $veget_version\" >> surface_env
echo 'orchidee_rev='$orchidee_rev >> surface_env
echo 'suforch='$suff_orc >> surface_env
