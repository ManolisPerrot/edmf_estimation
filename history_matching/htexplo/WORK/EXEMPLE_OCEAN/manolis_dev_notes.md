# Si ça fait longtemps, pour retester 
cd history_matching/htexplo/WORK/EXEMPLE_OCEAN/
bash exemple.sh -wave 1

faire des autres waves ça marche

# Documentation

- TODO: document installation and conda envs


My SCM model setup is in MODEL/SCMOCEAN, containing:
- param: text file with parameter to calibrate, min nominal max values and log/linear (warning, log not working for negative values)
- 


# exemple.sh
- [X] est-ce que VAR c'est variance ou std ? --> variance, mais si on utilise metric ~ theta^2 c'est bon
- [X] debugger exemple.sh de EXEMPLE
- [X] mettre wp0 en log dans param et adapter scm_model ! 
- [X] loop on cases (in input of parallelized metrics)
- [X] specify different metrics type (in input of parallelized metrics)
- [ ] comprendre -NLHC 1

Multi metrics and multi waves are working !


# Sensitivity results from Couvreux 2021 
- convergence criterion based on remaining space 
- reducing tolerance (VAR) --> NROY disminshes, but when tol < error_data no more effect
- succesive metrics or simulataneous metrics: after several waves, same NROY. Focus on some aspects can be put w/ succesive apporaches, or highly non-linear metrics...
- greater number of SCM runs: faster covergence ? 




- [ ] andrew plots (check Couvreux paper scripts and diags)

- [ ] faire les plots de la fig. 3 de Couvreux
----
<!-- - [ ] enable automatic multi waves, w/ option -wave 1 2 3 etc -->
- [X] check recommended number of SCM runs (I think is 10 x nb parameters)
- [ ] check recomended number for $sample_size 
  - dans Couvreux (2021) iels semblent utiliser 5 000 000 ?
  - [ ] regarder thèse Volodina ?
  - [ ] default dans Bench: 300 000 
- [X] modify wp0 range
- [X] check consistent range w/ MCMC
- [X] tester les mêmes tolérances que MCMC --> marche pas ?
- [X] faire une boucle pour s'arrêter quand NROY à convergé (regarder)
- [ ] log plot for wp0 ?
- [ ] add TKE metric

- [ ] faire proprement la doc "usage" dans exemple.sh, car là c'est pas cohérent


21/2/25: -j'ai lancé test pour FC_TH VAR=1.7e-05, 90 scm, 300000 GP --> NROY=1, pas de contraintes
         - reteste avec VAR 1.5e-6 --> pareil

Questions for dephy:
- [ ] comment choisir NLHC ?
- [ ] comment choisir nb GP ?

----------------------------------------------------------
(Vielles notes archivées, quand j'étais parti sur utiliser le framework bench.sh qui est finalement assez lourd. Finalement j'utilise exemple.sh qui est plus simple)

<!-- # Bench
- [X] SCMOCEAN/param_edmf OK: contient les paramètres à calibrer, avec range et 'linear' ou 'log' !! 
- [ ] pas compris ce paramètre: NLHC: if NLHC=1, then generate the maximinLHS of size LHCSIZE.
- [X] 2/ building design for WAVE1: working! il y avait 2 pb:
  - il fallait installer DoE.wrapper qui nécessitait de faire `conda install -c conda-forge gmp`
  - dans le fichier param
- [ ] trouver comment définir les métriques pour que les cas soient les bons  




# serie

- [X] comprendre si param.asc est bien le fichier txt créé qui contient les params sur lequels on va évaluer le SCM  NON, c'est dans Par1D_Wave1.asc, param est juste un lien symbolique
- [X] faire marcher bench.sh pour générer Par1D_Wave1.asc
- [X] ouvrir Par1D_Wave1.asc pour voir la strucure et écrire un script run_SCMOCE qui lit Par1D_Wav1.asc et fait tourner en parallèle le SCM. 
- [X] trouver où sauver les runs, et comment il faut les appeler.: ${simuREF}.${name}-${nwave}-$i?
   dans Readme:    netcdf ouptut files should be put in
   ./WAVE1/[cas] 
   with names SCM_1-101.nc given in Par1D_Wave1.asc
   Also put the available LES 1D output files in WAVE1
- [ ] renommer edmf_ocean en scmocean
- [X] dans serie_SMCOCEAN, à partir d'un moment faire juste tourner un script python plutôt que de s'mebetter avec le bash.
- [ ]  

# Compute metric

- [ ] il doit me manquer les LES dans REF, mais je comprends pas bien la structure/où les mettre
- [ ] idéalement: dans one_metric, j'appelle un script python qui me calcule ma métrique
 Suggestion Fred: on LAISSE TOMBER de le mettre dans leur framework SCM/LES, et on repart plus simplement du exemple.sh -->