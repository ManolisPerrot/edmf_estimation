# Mano
- [X] test lambda2=1e-3 regularization
- [X] compute reference likelihood3 on a 20x20x20 grid
- [X] send Benji .nc cases
- [ ] Sobol
- [ ] saving/plotting of MCMC
- [ ] how to save MCMC - MAP
- [ ] optimal number of samples?
- [ ] check Souza / Wagner implementation

Discussion with Maurice Brémond (automatic diff tool Tapenade):
- réécrire fontion cout en fortan
- appliquer tapenade dessus --> obtenir l’adjoint (mieux que le tangent)
    - il y a une option pour avoir tout dans le même .f90. Mieux pour éviter les pb de compil. Si ça bug trop, utiliser l’option pour séparer, mais il faut mettre tous les fichiers à compiler à la main
- utiliser f2py pour avoir cout et adjoint en python
- utiliser cout et adjoint pour MCMC
- [ ] Implement Hightune ??

# Benji
- [x] implement MCMC
- [ ] methods to diagnose MCMC
