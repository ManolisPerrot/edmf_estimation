# Bench
- [X] SCMOCEAN/param_edmf OK: contient les paramètres à calibrer, avec range et 'linear' ou 'log' !! 
- [ ] pas compris ce paramètre: NLHC: if NLHC=1, then generate the maximinLHS of size LHCSIZE.
- [X] 2/ building design for WAVE1: working! il y avait 2 pb:
  - il fallait installer DoE.wrapper qui nécessitait de faire `conda install -c conda-forge gmp`
  - dans le fichier param
- [ ] trouver comment définir les métriques pour que les cas soient les bons  




# serie

- [X] comprendre si param.asc est bien le fichier txt créé qui contient les params sur lequels on va évaluer le SCM --> NON, c'est dans Par1D_Wave1.asc, param est juste un lien symbolique
- [X] faire marcher bench.sh pour générer Par1D_Wave1.asc
- [X] ouvrir Par1D_Wave1.asc pour voir la strucure et écrire un script run_SCMOCE qui lit Par1D_Wav1.asc et fait tourner en parallèle le SCM. 
- [X] trouver où sauver les runs, et comment il faut les appeler.: ${simuREF}.${name}-${nwave}-$i?
  --> dans Readme:    netcdf ouptut files should be put in
   ./WAVE1/[cas] 
   with names SCM_1-101.nc given in Par1D_Wave1.asc
   Also put the available LES 1D output files in WAVE1
- [ ] renommer edmf_ocean en scmocean
- [X] dans serie_SMCOCEAN, à partir d'un moment faire juste tourner un script python plutôt que de s'mebetter avec le bash.
- [ ]  

# Compute metric

- [ ] il doit me manquer les LES dans REF, mais je comprends pas bien la structure/où les mettre
- [ ] idéalement: dans one_metric, j'appelle un script python qui me calcule ma métrique
--> Suggestion Fred: on LAISSE TOMBER de le mettre dans leur framework SCM/LES, et on repart plus simplement du exemple.sh
# Doc
To run:
- change conda env: 
  `conda deactivate`
  `conda activate hightune`

My SCM model setup is in MODEL/SCMOCEAN, containing:
- param: text file with parameter to calibrate, min nominal max values and log/linear (warning, log not working for negative values)
- 

# exemple.sh
- [X] est-ce que VAR c'est variance ou std ? --> variance, mais si on utilise metric ~ theta^2 c'est bon
- [X] debugger exemple.sh de EXEMPLE
- [X] mettre wp0 en log dans param et adapter scm_model ! 
- [ ] loop on cases (in input of parallelized metrics)
- [ ] specify different metrics type (in input of parallelized metrics)
- [ ] comprendre -NLHC 1

# compute_metrics.py
- [X] specify in input: waven, case, metrics type
- MANQUE de BIEN réécrire le CSV, je galèèèèèère