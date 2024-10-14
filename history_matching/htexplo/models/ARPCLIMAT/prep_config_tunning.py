import os
import sys

nsimus = int(sys.argv[1])
name = sys.argv[2]
case = sys.argv[3]
subcase = sys.argv[4]
nwave = sys.argv[5]
model = sys.argv[6]

config = sys.argv[7]
cycle = sys.argv[8]
MASTER = sys.argv[9]
PGD = sys.argv[10]
PREP = sys.argv[11]
namsfx = sys.argv[12]

repnamelist = os.getcwd() + '/WAVE{0}/namelist'.format(nwave) 

for i in range(0,nsimus):
  fout = 'config_{0}_{1}.{2}_{3}-{4:0>3}.py'.format(cycle,config,name,nwave,i+1)
  g = open(fout,'w')
  print >> g, "config = '{0}.{1}_{2}-{3:0>3}'".format(config,name,nwave,i+1)
  print >> g, "cycle = '{0}'".format(cycle)
  print >> g, "MASTER = '{0}'".format(MASTER)
  if model == 'ARPCLIMAT':
    print >> g, "PGD = '{0}'".format(PGD)
    print >> g, "PREP = '{0}'".format(PREP)
  print >> g, "namATMref = '{0}/namref.{1}_{2}-{3:0>3}'".format(repnamelist,name,nwave,i+1)
  if model == 'ARPCLIMAT':
    print >> g, "namSFXref = '{0}'".format(namsfx)
  g.close()

