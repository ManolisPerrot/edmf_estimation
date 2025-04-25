# Mano
-- [ ] fix emdf_ocean for small ap = False (causes many divergent values)
- [ ] check sensitivity of L2 and H1 likelihood to model_error
- [ ] infer data error from MNH/CROCO comparison 
- [X] configure likelihood to use wagner's LES --> NO because they have Stokes Drift !!!
- [ ] use Van Roekel cases
- [ ] portability: create a script to automatically create a conda env with required packages 
- [ ] extend the dataset to more cases + place cases of the literature on the non-dim space. 
- [ ] redo the two inferences with NaN fixed (start with 3 parameters Cent, ap0, wp_bp)
- [ ] sort and reorganize the folder...



# Benji
- [X] implement MCMC
- [X] methods to diagnose MCMC (check how good the MCMC is): put it in appendix of paper
- [X] how to save MCMC - MAP
- [ ] check leave one out etc for estimating beta
- [ ] filter samples according to likelihood and only plot those with likelihood > beta


# Sobol
- [ ] check if WANG1 is working
- [ ] (optional) do sensitivity to mean_u and mean_v outputs for WANG1
- [ ] do more samples w/ the new logwp0 range !! since total indices have not converged...

# Paper
- [ ] mieux articuler Sobol et Bayésien ? 
- [ ] quelle comparaison avec history matching ? forme générale des espaces et NROY 1D (ie intervalle de confiance à la fin ?)
- [ ] dire que notre modèles n'a pas de biais structurels, car après calibration il est bien capable de reproduire les LES à erreur donné près
- [ ] dire qu'en fait MCMC n'est pas efficace pcq manque de parralélisme, mais qu'en pratique évaluer les SCM c'est rapide si on a bcp de coeurs. 

- [ ] rajouter MAP output sur les andrew plots (et la LES?)
- [ ] faire des plots en série tempo ?
- [ ] tableau valeurs ltérature pour a et b
- [ ] Remise en contexte history matching dans Bayésien
- [ ] Wang1
- [ ] Résulats history matching
- [ ] Résultats Benji transport maps
- [X] TKE in metric 
   --> done, but do not constrain TKE. Pb w/ imposed model error ? Do a prec definition w/ hisotry matching ?
- [ ] extend prior ranges for Cent, a, wp0 etc
- [ ] attain convergence for Sobol w/ log wp0, and interprete total Sobol indices


----------------------

Discussion with Maurice Brémond (automatic diff tool Tapenade):
- réécrire fontion cout en fortan
- appliquer tapenade dessus --> obtenir l’adjoint (mieux que le tangent)
    - il y a une option pour avoir tout dans le même .f90. Mieux pour éviter les pb de compil. Si ça bug trop, utiliser l’option pour séparer, mais il faut mettre tous les fichiers à compiler à la main
- utiliser f2py pour avoir cout et adjoint en python
- utiliser cout et adjoint pour MCMC