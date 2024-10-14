import os
import sys

#import configMUSC

nsimus = int(sys.argv[1])
name = sys.argv[2]
case = sys.argv[3]
subcase = sys.argv[4]
nwave = sys.argv[5]
model = sys.argv[6]

config = sys.argv[7]
cycle = sys.argv[8]
MASTER = sys.argv[9]
if model == 'ARPCLIMAT':
  PGD = sys.argv[10]
  PREP = sys.argv[11]
  namsfx = sys.argv[12]
  


#rep0 = configMUSC.mainrep

#if model == 'ARPCLIMAT':
#  config = 'CMIP6'
#  cycle = 'arp631'
#  MASTER = '/Users/romainroehrig/rootpack/arp603_export.01.MPIGNU640.x/bin/MASTERODB'
#  PGD = '/Users/romainroehrig/rootpack/arp603_export.01.MPIGNU640.x/bin/PGD'
#  PREP = '/Users/romainroehrig/rootpack/arp603_export.01.MPIGNU640.x/bin/PREP'
#elif model == 'AROME':
#  config = 'AROME_OPER'
#  cycle = '41t1_op1.11_MUSC'
#  MASTER ='/home/honnert/Bureau/MUSC/pack/' + cycle + '/bin/MASTERODB'
#elif model == 'ARPEGE':
#  config = 'ARPEGE_OPER'
#  cycle = '41t1_op1.11_MUSC'
#  MASTER = '/home/honnert/Bureau/MUSC/pack/' + cycle + '/bin/MASTERODB'

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

