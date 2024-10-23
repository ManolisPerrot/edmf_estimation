##########################################################
# Checking the availability of R pacakages and installing
# them if needed
# Authors : Najda Villefranque and Frédéric Hourdin
##########################################################

#packages='rappdirs jsonlite reticulate invgamma GenSA far fields lhs maps mco mvtnorm ncdf4 parallel shape tensor withr loo MASS'
# Not available : parallel mtvnorm
#packages='reticulate invgamma GenSA far fields lhs maps mco ncdf4 shape tensor withr loo MASS pracma'

packages="$*"

##########################################################
# Lines below should be useless. It is a R standard
# And if R has been installed in another but consistent
# way, .Renviron may be useless
##########################################################
#if [ -f ~/.Renviron ] 
#then
#  source ~/.Renviron
#else 
#  echo "error: There is no file ~/.Renviron" 
#  exit 1
#fi 
#if [ ! -d $R_LIBS_USER ] || [ "$R_LIBS_USER" = "" ]
#then 
#  echo "error: Environment variable R_LIBS_USER (${R_LIBS_USER}) was not properly set."
#  exit 1
#fi 
##########################################################

# If a package cannot be downloaded using 
# echo 'install.packages("'$p'",contriburl="https://cran.rstudio.com/src/contrib",method="wget", lib="'$R_LIBS_USER'") ; quit() ;' > tmp.R
# should try downloading an archive directly, eg using 
# echo 'install.packages("https://cran.r-project.org/src/contrib/Archive/maps/maps_3.4.0.tar.gz", repos=NULL, type="source", method="wget", lib="'$R_LIBS_USER'") ; quit() ;' > tmp.R

##########################################################

. ~/.Renviron

echo $R_LIBS_USER
ls $R_LIBS_USER
for p in $packages 
do 
  if [ -d $R_LIBS_USER/$p ]
  then 
    echo "Found "$p" in "$R_LIBS_USER
  else
    case $p in
    HI|MfUSampler|MASS)
       case $p in
          HI) version=0.5 ;;
          MfUSampler) version=1.0.6 ;;
          MASS) version=7.3-58.3 ;;
       esac
       echo 'install.packages("https://cran.r-project.org/src/contrib/Archive/'${p}/${p}_${version}'.tar.gz", repos=NULL, type="source", method="wget", lib="'$R_LIBS_USER'") ; quit() ;' > tmp.R ;;
    *)
       # Specification of lib="'$R_LIBS_USER'" is probably useless as well
       echo 'install.packages("'$p'",contriburl="https://cran.rstudio.com/src/contrib", method="wget", lib="'$R_LIBS_USER'") ; quit() ;' > tmp.R ;;
    esac
    Rscript tmp.R
    if [ ! -d $R_LIBS_USER/$p ] ; then echo Problem encountered when installing R package $p ; exit 1 ; fi
    rm tmp.R
  fi
done 
