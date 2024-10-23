## 28/05/2024
# @Najda
# documente l'utilisation des scripts *emulator_predictions*

exe=exemple.sh

# clean depo 
bash $exe clean

# run 3 waves of exemple
for i in 1 2 3 
do 
  bash $exe $i
done

# generate Predictions_Wave3.asc containing expectation & variance of emulators
# for all metrics and waves up to 3th
Rscript htune_emulator_predictions.R -wave 3

# plot results, waves 1,2,3, only as a function of parameter a
# -y == ylim of the plots
python htune_plot_emulator_predictions.py -w 1,2,3 -p a

exit

## version du 04/04
# clean depo 
bash $exe clean

# run 7 waves of exemple, introduce a second metric at 6th wave
for i in 1 2 3 4 5 6 7 
do 
  bash $exe $i 6
done

# generate Predictions_Wave7.asc containing expectation & variance of emulators
# for all metrics and waves up to 7th
Rscript htune_emulator_predictions.R -wave 7

# plot results, only waves 1,3,5,6,7 , only as a function of parameter a
# -y == ylim of the plots
python htune_plot_emulator_predictions.py -w 1,3,5,6,7 -p a -y " -0.7,1.25"
