######################################################
# Author : Frederic Hourdin
# Ploting scores, sorted
######################################################

import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import sys

plt.figure(figsize=(15,7))


listFiles = sys.argv[1:-1]
title = sys.argv[-1]

for ifi,fic in enumerate(listFiles):
    x = []
    for l in open(fic) : 
        x+=[np.float(l.split()[0])]
    y=np.sort(x)
    y=x
    if ifi > 3:
        linew=1.
    else:
        linew=4.
        
    if ifi > 20:
        style="--"
    elif ifi > 10:
        style="-."
    else:
        style="-"
    plt.semilogy(y,label=fic,linestyle=style,linewidth=linew)

plt.legend(bbox_to_anchor=(1., 0., 0., 1.))
plt.xlabel('Sample number (sorted)')
plt.ylabel(title)
plt.tight_layout()
plt.savefig('tmp.pdf')
