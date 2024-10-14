# This should install ecrad in some directory and build it
#echo "Null for now!"

#This script install and compile ecrad
ROOT=`pwd`
ECRAD=ecrad
ECRADroot=""
if [ -d $ROOT/../../$ECRAD ] ; then
   ECRADroot=$ROOT/../..
else
   # By default, ECRAD is installed next to HighTune like LMDZ
   ECRADroot=$ROOT/..
fi
ECRADdir=$ECRADroot/$ECRAD
sed -e 's:ECRAD=.*.$:ECRAD='$ECRADdir':' $ROOT/models/ECRAD/serie_ECRAD.sh >| tmp
\mv -f tmp $ROOT/models/ECRAD/serie_ECRAD.sh
chmod +x $ROOT/models/ECRAD/serie_ECRAD.sh

if [ ! -d $ECRADdir ] ; then
  echo ECRAD installation 
  cd $ECRADroot
  git clone https://github.com/ecmwf/ecrad
  cd $ECRAD
  make PROFILE=gfortran
  git clone https://gitlab.com/najdavlf/dephy2ecrad/ -b master dephy2ecRad
  #wget https://web.lmd.jussieu.fr/~nvillefranque/pub/codes/dephy2ecRad.tar 
  #tar xvf dephy2ecRad.tar
fi
