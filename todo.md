# Mano
- [X] test lambda2=1e-3 regularization
- [X] compute reference likelihood3 on a 20x20x20 grid
- [X] send Benji .nc cases
- [X] Sobol
- [X] saving/plotting of MCMC
- [ ] optimal number of samples? --> open question with MCMC
- [X] check Souza implementation (useless)
- [ ] fix emdf_ocean for small ap = False (causes many divergent values)
- [X] check pelletier paper on Sobol: they don't do much 
- [X] check 2nd order sobol indices
- [X] *VERIFY THAT interpolate les on scm IS CORRECT!!!*
- [ ] check sensitivity of L2 and H1 likelihood to model_error
- [ ] infer data error from MNH/CROCO comparison 
- [X] ask Florian the access of Wagner's LES
- [X] configure likelihood to use wagner's LES --> NO because they have Stokes Drift !!!
- [ ] use Van Roekel cases
- [X] compute beta from loss between MAP and LES
- [X] refaire tourner les cas pour être sûr des params thermo? (en vérifiant bien le grad de temp...)
- [X] PB with FC500, MAP is not really matching (offset of temp, already found before... Pb of thermo cst?)
- [X] fix cp on FC500 to avoid bias.
- [X] do a Andrew plot with full distribution, then distribution cutted above a trshold of high proba to see how it is reducing the variability. 
- [ ] REDO Andrew with not saving but keeping in local memory, for it to go faster
- [ ] check Andrew plot with plotting all the lines, same color and alpha =0.5 to see really the density
- [ ] run the script on 9 cores on dahu
- [ ] portability: create a script to automatically create a conda env with required packages 
- [ ] 

Discussion with Maurice Brémond (automatic diff tool Tapenade):
- réécrire fontion cout en fortan
- appliquer tapenade dessus --> obtenir l’adjoint (mieux que le tangent)
    - il y a une option pour avoir tout dans le même .f90. Mieux pour éviter les pb de compil. Si ça bug trop, utiliser l’option pour séparer, mais il faut mettre tous les fichiers à compiler à la main
- utiliser f2py pour avoir cout et adjoint en python
- utiliser cout et adjoint pour MCMC
  
- [ ] Implement Hightune ??

- [ ] do andrew plots / check souza 
- [ ]

- [ ] redo the two inferences with NaN fixed (start with 3 parameters Cent, ap0, wp_bp)

# Benji
- [X] implement MCMC
- [X] methods to diagnose MCMC (check how good the MCMC is): put it in appendix of paper
- [X] how to save MCMC - MAP
- [ ] check leave one out etc for estimating beta
- [ ] filter samples according to likelihood and only plot those with likelihood > beta


# Sobol
- [X] plot results
- [ ] check if WANG1 is working
- [X] check default params comapred to paper
- [X] test sentivity to nulber of samples, for FC500 only : OK, z indices are very well converged at N=4096 but...
- [ ] (optional) do sensitivity to mean_u and mean_v outputs for WANG1
- [X] compute total sobol index ? Since 1st index can 
- [X] check openturns library to look for explanations on SA.   
- [X] refactoring of the code: separate sample generation and saving from Sobol computation
- [X] do more samples since total z indices have not converged...

