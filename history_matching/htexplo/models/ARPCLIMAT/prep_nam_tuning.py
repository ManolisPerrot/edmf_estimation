import numpy
import os

debug=False
# rajouter pour enlever les " par le script de Fred
os.system("sed 's/\"//g' param.asc > tmp")

f = open('tmp')
lines = f.readlines()
f.close()

os.system('rm -f tmp')


nsimus = len(lines)-1

tmp = lines[0].split()
np = len(tmp)-1

parameters = []
for ip in range(0,np):
  toto = tmp[ip+1]
  parameters.append(toto)

values = numpy.zeros((nsimus,np),dtype=numpy.float)
names = []
for il,line in enumerate(lines[1:]):
  tmp = line.split()
  names.append(tmp[0])
  if debug: print 'simu=',tmp[0]
  for ip in range(0,np):
    toto = tmp[ip+1]
    values[il,ip] = float(toto)
    if debug: print 'val ',parameters[ip],values[il,ip]



for isim in range(0,nsimus):
    ext = names[isim]
    cmd = 'cp {0:s} {0:s}.{1:s}'.format('namref',ext)
    if debug: print cmd
    os.system(cmd)
    for ip in range(0,np):
        pp = parameters[ip]
        cmd = "sed -e 's/{0:s}=.*/{0:s}={1:e},/' {2:s}.{3:s} > tmp".format(pp,values[isim,ip],'namref',ext)
        if debug: print cmd
        os.system(cmd)
        cmd = 'cp tmp {0:s}.{1:s}'.format('namref',ext)
        if debug: print cmd
        os.system(cmd)

os.system('rm -f tmp')
