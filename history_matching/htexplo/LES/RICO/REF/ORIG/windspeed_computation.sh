echo '############################################################## '
echo '###### CALCUL DE L INTENSITE DU VENT DANS LES FICHIERS LES  #####'
echo -e '############################################################## \n'

# Code ok pour toutes les LES mais a lancer dans le repertoire ORIG


for simu in `ls *.nc`
do
    echo 'Ajout de wind speed dans' ${simu}
    ncap2 -s "WND=sqrt(u*u+v*v)" ${simu} tmp_${simu}
    rm -f ${simu}
    mv tmp_${simu} ${simu}
    ncatted -O -a long_name,WND,o,c,"Wind speed" ${simu}
done
