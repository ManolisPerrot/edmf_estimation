# from J. Barbier pvwave script 
import numpy as np

linestyles = 100*['-','--','-.',':']

red = [float(i)/255. for i in [0,68,204,221,140,66,255]]
green = [float(i)/255. for i in [0,119,102,221,140,66,255]]
blue = [float(i)/255. for i in [0,170,119,221,140,66,255]]
basic2= np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,68,221,204,221,140,66,255]]
green = [float(i)/255. for i in [0,119,204,119,221,140,66,255]]
blue = [float(i)/255. for i in [0,170,119,119,221,140,66,255]]
basic3= np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,64,17,221,204,221,140,66,255]]
green = [float(i)/255. for i in [0,119,119,204,102,221,140,66,255]]
blue = [float(i)/255. for i in [0,170,51,119,119,221,140,66,255]]
basic4 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,51,136,17,221,204,221,140,66,255]]
green = [float(i)/255. for i in [0,34,204,119,204,102,221,140,66,255]]
blue = [float(i)/255. for i in [0,136,238,51,119,119,221,140,66,255]]
basic5 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,51,136,17,221,204,170,221,140,66,255]]
green = [float(i)/255. for i in [0,34,204,119,204,102,68,221,140,66,255]]
blue = [float(i)/255. for i in [0,136,238,51,119,119,153,221,140,66,255]]
basic6 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,51,136,68,17,221,204,170,221,140,66,255]]
green = [float(i)/255. for i in [0,34,204,170,119,204,102,68,221,140,66,255]]
blue = [float(i)/255. for i in [0,136,238,153,51,119,119,153,221,140,66,255]]
basic7 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,51,136,68,17,153,221,204,170,221,140,66,255]]
green = [float(i)/255. for i in [0,34,204,170,119,153,204,102,68,221,140,66,255]]
blue = [float(i)/255. for i in [0,136,238,153,51,51,119,119,153,221,140,66,255]]
basic8 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,51,136,68,17,153,221,204,136,170,221,140,66,255]]
green = [float(i)/255. for i in [0,34,204,170,119,153,204,102,34,68,221,140,66,255]]
blue = [float(i)/255. for i in [0,136,238,153,51,51,119,119,85,153,221,140,66,255]]
basic9 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,51,136,68,17,153,221,102,204,136,170,221,140,66,255]]
green = [float(i)/255. for i in [0,34,204,170,119,153,204,17,102,34,68,221,140,66,255]]
blue = [float(i)/255. for i in [0,136,238,153,51,51,119,0,119,85,153,221,140,66,255]]
basic10 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,51,102,136,68,17,153,221,102,204,136,170,221,140,66,255]]
green = [float(i)/255. for i in [0,34,153,204,170,119,153,204,17,102,34,68,221,140,66,255]]
blue = [float(i)/255. for i in [0,136,204,238,153,51,51,119,0,119,85,153,221,140,66,255]]
basic11 = np.array([red,green,blue]).transpose()
                           #   0  1  2    3   4   5   6  7    8   9  10  11  12  13  14  15  16
red = [float(i)/255. for i in [0, 51,102, 136,68, 17,153,221,102,204,170,136,170,221,140,66,255]]
green = [float(i)/255. for i in [0,34,153,204,170,119,153,204,17,102,68, 34, 68, 221,140,66,255]]
blue = [float(i)/255. for i in [0,136,204,238,153,51, 51,119,  0,119,102,85, 153,221,140,66,255]]
basic12 = np.array([red,green,blue]).transpose()

basics=[basic2,basic3,basic4,basic5,basic6,basic7,basic8,basic9,basic10,basic11,basic12]

######## Rainbow ########

red = [float(i)/255. for i in [0,64,87,222,217,221,140,66,255]]
green = [float(i)/255. for i in [0,64,163,167,33,221,140,66,255]]
blue = [float(i)/255. for i in [0,150,173,58,32,221,140,66,255]]
rainbow4 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,64,82,125,227,217,221,140,66,255]]
green = [float(i)/255. for i in [0,64,157,184,156,33,221,140,66,255]]
blue = [float(i)/255. for i in [0,150,183,116,55,32,221,140,66,255]]
rainbow5 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,60,73,99,190,230,217,221,140,66,255]]
green = [float(i)/255. for i in [0,64,140,173,188,139,33,221,140,66,255]]
blue = [float(i)/255. for i in [0,150,194,153,72,51,32,221,140,66,255]]
rainbow6 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,120,63,83,109,202,231,217,221,140,66,255]]
green = [float(i)/255. for i in [0,28,96,158,179,184,133,33,221,140,66,255]]
blue = [float(i)/255. for i in [0,129,174,182,136,67,50,32,221,140,66,255]]
rainbow7 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,120,63,75,95,145,216,231,217,221,140,66,255]]
green = [float(i)/255. for i in [0,28,86,145,170,189,175,124,33,221,140,66,255]]
blue = [float(i)/255. for i in [0,129,127,192,159,97,61,48,32,221,140,66,255]]
rainbow8 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,120,63,70,87,109,177,223,231,217,221,140,66,255]]
green = [float(i)/255. for i in [0,28,78,131,163,179,190,165,116,33,221,140,66,255]]
blue = [float(i)/255. for i in [0,129,161,193,173,136,78,58,47,32,221,140,66,255]]
rainbow9 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,120,63,66,82,98,134,199,227,231,217,221,140,66,255]]
green = [float(i)/255. for i in [0,28,71,119,157,172,187,185,156,109,33,221,140,66,255]]
blue = [float(i)/255. for i in [0,129,155,189,183,155,106,68,55,46,32,221,140,66,255]]
rainbow10 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,120,64,65,77,91,110,161,211,229,230,217,221,140,66,255]]
green = [float(i)/255. for i in [0,28,64,108,149,167,179,190,179,148,104,33,221,140,66,255]]
blue = [float(i)/255. for i in [0,129,150,183,190,167,135,86,63,53,45,32,221,140,66,255]]
rainbow11 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,120,65,64,72,85,99,127,181,217,230,230,217,221,140,66,255]]
green = [float(i)/255. for i in [0,28,59,101,139,161,173,185,189,173,142,100,33,221,140,66,255]]
blue = [float(i)/255. for i in [0,129,147,177,194,177,153,114,76,60,52,44,32,221,140,66,255]]
rainbow12 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,136,177,214,25,82,123,78,144,202,247,246,241,232,220,221,140,66,255]]
green = [float(i)/255. for i in [0,46,120,193,101,137,175,178,201,224,238,193,147,96,5,221,140,66,255]]
blue = [float(i)/255. for i in [0,114,166,222,176,199,222,101,135,171,85,65,45,28,12,221,140,66,255]]
rainbow14 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,17,68,119,17,68,153,119,170,221,119,170,221,119,170,221,221,140,66,255]]
green = [float(i)/255. for i in [0,68,119,170,119,170,204,119,170,221,17,68,119,17,68,119,221,140,66,255]]
blue = [float(i)/255. for i in [0,119,170,221,85,136,187,19,68,119,17,68,119,68,119,170,221,140,66,255]]
rainbow15 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,119,170,204,17,68,117,17,68,119,119,170,221,119,170,221,119,170,221,221,140,66,255]]
green = [float(i)/255. for i in [0,17,68,153,68,119,170,119,170,204,119,170,221,68,119,170,17,68,119,221,140,66,255]]
blue = [float(i)/255. for i in [0,85,136,187,119,170,221,119,170,204,17,68,119,17,68,119,34,85,136,221,140,66,255]]
rainbow18 = np.array([red,green,blue]).transpose()

red = [float(i)/255. for i in [0,119,170,204,17,68,119,17,68,119,17,68,136,119,170,221,119,170,221,119,170,221,66,140,221,140,66,255]]
green = [float(i)/255. for i in [0,17,68,153,68,119,170,119,170,204,119,170,204,119,170,221,68,119,170,17,68,119,66,140,221,140,66,255]]
blue = [float(i)/255. for i in [0,85,136,187,119,170,221,119,170,204,68,119,170,17,68,119,17,68,119,34,85,136,66,140,221,140,66,255]] 
rainbow21 = np.array([red,green,blue]).transpose()

rainbows = [rainbow4,rainbow5,rainbow6,rainbow7,rainbow8,rainbow9,rainbow10,rainbow11,rainbow12,rainbow14,rainbow15,rainbow18,rainbow21]

if __name__ =="main" :
    from matplotlib import pyplot as plt
    fig = plt.figure()
    listCols = basics
    for i,col in enumerate(listCols) :
      if i==0 : 
        ax = fig.add_subplot(len(listCols),1,i+1)
        ax0=ax 
      ax = fig.add_subplot(len(listCols),1,i+1,sharex=ax0)
      x = range(len(col))
      ax.vlines(x,0,1,colors=col,linewidth=10)
    plt.savefig("basics.pdf")
    fig = plt.figure()
    listCols = rainbows
    for i,col in enumerate(listCols) :
      if i==0 : 
        ax = fig.add_subplot(len(listCols),1,i+1)
        ax0=ax 
      ax = fig.add_subplot(len(listCols),1,i+1,sharex=ax0)
      x = range(len(col))
      ax.vlines(x,0,1,colors=col,linewidth=10)
    plt.savefig("rainbows.pdf")
    plt.close()

