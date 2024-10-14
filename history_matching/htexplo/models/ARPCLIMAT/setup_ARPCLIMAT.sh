

# To be modified if namelists and binaries are not at the default location
#PREP=/home/common/pack/arp603_export.01.GFORTRAN610.cx/bin/PREP
cat << EOF > models/ARPCLIMAT/param_ARPCLIMAT
nlev=91
timestep=300
cycle=arp631
simuREF=CMIP6
namref=$REP_MUSC/namelist/ARPCLIMAT/nam.atm.tl127l91r.CMIP6.v631

namsfx=$REP_MUSC/namelist/SURFEX/nam.sfx.tl127.CMIP6.v631

MASTER=/home/common/pack/arp631/bin/MASTER
PGD=/home/common/pack/arp631/bin/PGD
PREP=/home/common/pack/arp631/bin/PREP
#MASTER=/Users/romainroehrig/rootpack/arp603_export.01.MPIGNU640.x/bin/MASTERODB
#PGD=/Users/romainroehrig/rootpack/arp603_export.01.MPIGNU640.x/bin/PGD
#PREP=/Users/romainroehrig/rootpack/arp603_export.01.MPIGNU640.x/bin/PREP
EOF
