# Bench
- [X] SCMOCEAN/param_edmf OK: contient les paramètres à calibrer, avec range et 'linear' ou 'log' !! 
- [ ] pas compris ce paramètre: NLHC: if NLHC=1, then generate the maximinLHS of size LHCSIZE.
- [ ] continuer avec bench.sh: pb avec Par1D_Wave1:
  
        =====================================================================
        O/ default values and reading arguments
        =====================================================================
        =====================================================================
        1/ experiment setup and controls
        =====================================================================
        ======================================================================
        1C/ Running setup.sh SCMOCEAN for a new experiment
        ======================================================================
        Running ./setup.sh SCMOCEAN BENCHSCMOCEAN : log in log/setup_SCMOCEAN65324
        STARTING LOOP ON WAVES ON WORK/BENCHSCMOCEAN
        ======================================================================
        2/ Building design for wave 1
        ======================================================================
        cp: cannot stat 'Wave1.RData': No such file or directory
        ./param2R.sh param
        fichier param inexistant
        Rscript htune_convertDesign.R -LHCSIZE 46 -NLHC 1
        [1] "args[iarg], 1 -LHCSIZE"
        [1] "LHCSIZE= 46"
        [1] "args[iarg], 3 -NLHC"
        [1] "WAVEN " "1"     
        Loading required package: DoE.wrapper
        Loading required package: DiceDesign
        Loading required package: parallel
        Warning messages:
        1: In library(package, lib.loc = lib.loc, character.only = TRUE, logical.return = TRUE,  :
        there is no package called 'DoE.wrapper'
        2: In library(package, lib.loc = lib.loc, character.only = TRUE, logical.return = TRUE,  :
        there is no package called 'DiceDesign'
        [1] "--------------------------------"
        [1] "Generating or scaling parameters"
        [1] "--------------------------------"
        Error in file(filename, "r", encoding = encoding) : 
        cannot open the connection
        Calls: source -> file
        In addition: Warning message:
        In file(filename, "r", encoding = encoding) :
        cannot open file 'ModelParam.R': No such file or directory
        Execution halted
        mv: cannot stat 'Wave1.RDat*': No such file or directory
        mv: cannot stat 'Par1D_Wave1.asc': No such file or directory
        ======================================================================
        3/ Running the requires SCM simulations for wave 1
        ======================================================================
        LIST SIMU SCM: RICO/REF
        LIST SIMU RAD:
        ./serie_SCMOCEAN.sh RICO/REF 1 > /home/manolis/Documents/these/SCM_EDMF/edmf_estimation/history_matching/htexplo/WORK/BENCHSCMOCEAN/log/serie_1.log
        Error during serie_SCMOCEAN.sh



# serie

- [X] comprendre si param.asc est bien le fichier txt créé qui contient les params sur lequels on va évaluer le SCM --> NON, c'est dans Par1D_Wave1.asc, param est juste un lien symbolique
- [ ] faire marcher bench.sh pour générer Par1D_Wave1.asc
- [ ] ouvrir Par1D_Wave1.asc pour voir la strucure et écrire un script run_SCMOCE qui lit Par1D_Wav1.asc et fait tourner en parallèle le SCM. 