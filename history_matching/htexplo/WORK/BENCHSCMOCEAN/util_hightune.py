#-*- coding:UTF-8 -*-
# fonctions utiles pour gabls4 python
#import netCDF4 as nc4
from datetime import timedelta
import numpy as np

def is_init(var):
    '''
    teste si une variable est initialisée
    '''
    if (var or var == 0):
        return True
    else:
        return False

def presence_var(ncfid,nomvar):
    '''
    teste la presence d'une variable dans un fichier netcdf
    ncfid : objet dataset netCDF4
    nomvar : nom de variable
    '''
    try:
        ncfid.variables[nomvar]
        return True
    except KeyError:
        return False

def with_valid(nomtab):
    '''
    nomtab : tableau masqué ou non
    '''
    try:
        if nomtab.mask.all():
            # tout est masqué
            return False
        else:
            return True
    except AttributeError:
        # si l'attribut "mask" n'est pas trouvé
        return True

def ind_plusproche(tab,search,axis=0):
    '''
    tab : tableau de valeurs
    search : valeur recherchée
    renvoie les indices dans tab selon l'axe demandé, de la valeur la plus proche de search
    '''
    diff=abs(tab-search)
    return np.argmin(diff,axis=axis)

def data_pourprofil(ncfid,nomvar,axevert,mesg):
    '''
    ncfid : objet dataset netCDF4
    nomvar : nom de variable
    axevert : axe vertical 'z' ou 'p'
    mesg : message d'erreur en sortie, de type liste
    vérification de la présence des données nécessaires au tracé du profil vertical
    '''
    if(not isinstance(mesg, list)) :
      mesg=list(mesg)
    # vérif présence de la variable
    if ( not presence_var(ncfid,nomvar) ):
        mesg.append("ne contient pas de variable %s" % (nomvar))
        return False

    # vérif présence de la variable avec les données verticales
    nomdim=ncfid.variables[nomvar].dimensions
    #on déduit le type de niveau de la variable (f ou h) du nom de sa 2ieme dimension (levf ou levh normalement),
    nomz=nomdim[1]
    # variable verticale correspondante : zf ou zh, pf ou ph
    varvert=axevert+nomz[-1]
    if ( not presence_var(ncfid,varvert) ):
        mesg.append("erreur donnees verticale, pas de variable %s" % (varvert))
        return False

    # retour ok
    return True

def data_pourserietempo(ncfid,nomvar,mesg,niv=None):
    '''
    ncfid : objet dataset netCDF4
    nomvar : nom de variable
    mesg : message d'erreur en sortie, de type liste
    vérification de la présence des données nécessaires au tracé de serie temporelle
    '''
    if(not isinstance(mesg, list)) :
      mesg=list(mesg)
    # vérif présence de la variable
    if ( not presence_var(ncfid,nomvar) ):
        mesg.append("ne contient pas de variable %s" % (nomvar))
        return False

    # vérif dimensions de la variable
    nomdim=ncfid.variables[nomvar].dimensions
    if (nomdim[0] != 'time'):
        mesg.append("la variable %s n'a pas de 1ere dimension time" % (nomvar))
        return False
    nbdim=len(nomdim)
    dims=ncfid.variables[nomvar].shape
    # si plus d'une dimension
    if (nbdim > 1):
        # si pas de niveau demandé la variable doit être 1d : les dimensions de 1 à nbdim ne doivent pas être supérieures à 1
        if not is_init(niv) :
            for i in range(1,nbdim):
                if (dims[i] > 1): 
                    mesg.append("la variable %s n'est pas 1d : dimension %s = %d et pas de niveau selectionne" % (nomvar,nomdim[i],dims[i]))
                    return False
        # si un niveau demandé la variable doit être 2d : les dimensions de 2 à nbdim ne doivent pas être supérieures à 1
        else:
            for i in range(2,nbdim):
                if (dims[i] > 1): 
                    mesg.append("un niveau a ete selectionne, mais la variable %s n'est pas 2d : dimension %s = %d et pas de niveau selectionne" % (nomvar,nomdim[i],dims[i]))
                    return False

    # retour ok
    return True

def recup_champ(ncfid,nomvar,mesg):
    '''
    recupere le champ 1d ou 2d
    si la variable a plus de 2 dimensions, les autres dimensions doivent être égales à 1
    '''
    # dimensions
    nomdim=ncfid.variables[nomvar].dimensions
    nbdim=len(nomdim)

    # si nomvar a plus de 2 dimensions
    if (nbdim > 2):
        dims=ncfid.variables[nomvar].shape
        # verification : taille de la variable = nombre de valeurs dim1 x nombre de valeurs dim2
        size12=dims[0]*dims[1]
        sizetot=ncfid.variables[nomvar].size
        #print 'sizetot=',sizetot,' size12=',size12
        if (size12 == sizetot): 
            # on redimensionne pour enlever les dimensions de taille 1
            dimstab=np.array(dims)
            newshape=tuple(dimstab[dimstab>1])
            data=np.reshape(ncfid.variables[nomvar][:],newshape)
            return data
        else:
            mesg.append("%s n'est pas de dimension 2, dimensions : %s" % (nomvar,dims))

    # cas où nomvar a 1 ou 2 dimensions
    else:
        # renvoie un champ 1d ou 2d
        data=ncfid.variables[nomvar][:]
        return data

def titre_nomfic(nomfic):
    '''
    label en fonction du nom de fichier.
    enleve le prefixe du nom de fichier si celui-ci commence par time_ ou prof_
    '''
    base_nomfic=nomfic.split('/')[-1]
    champs_nomfic=base_nomfic.split('_')
    if (champs_nomfic[0]=='time' or champs_nomfic[0]=='prof'):
        return base_nomfic[len(champs_nomfic[0])+1:-3]
    else:
        return base_nomfic[0:-3]
    #return base_nomfic[0:-3]

def basefic(nomfic):
    '''
    nom de fichier sans le chemin.
    enleve le prefixe du nom de fichier si celui-ci commence par time_ ou prof_
    '''
    base_nomfic=nomfic.split('/')[-1]
    champs_nomfic=base_nomfic.split('_')
    if (champs_nomfic[0]=='time' or champs_nomfic[0]=='prof'):
        return base_nomfic[len(champs_nomfic[0])+1:]
    else:
        return base_nomfic[:]

def test_ficstat(listfic):
    '''
    vérifie si la liste des fichiers en argument contient les fichiers qui débutent par ensmin ou ensmax, 
    prefixé éventuellemant par time_ ou prof_
    renvoie un dictionnaire contenant un dico avec les noms de fichiers pour les clés "ensmin" et "ensmax" 
    '''
    nom_ensmin=False
    nom_ensmax=False
    dico_ens={}
    for nomfic in listfic:
        # noms de fichier sans chemin et prefixe
        debutnom=basefic(nomfic).split('_')[0]
        if (debutnom == 'ensmin'):
            finnom=basefic(nomfic)[len(debutnom)+1:]
            nom_ensmin=nomfic
            #print 'debutnom: ',debutnom,' finnom: ',finnom
            if not dico_ens.has_key(finnom):
                dico_ens[finnom]={"ensmin": nom_ensmin}
                dico_ens[finnom]["ensmax"]=0
            else:
                dico_ens[finnom]["ensmin"]=nom_ensmin
        if (debutnom == 'ensmax'):
            nom_ensmax=nomfic
            finnom=basefic(nomfic)[len(debutnom)+1:]
            nom_ensmin=nomfic
            if not dico_ens.has_key(finnom):
                dico_ens[finnom]={"ensmax": nom_ensmax}
                dico_ens[finnom]["ensmin"]=0
            else:
                dico_ens[finnom]["ensmax"]=nom_ensmax
    return dico_ens

def titre_champ(ncfid,nomvar,titre_nomvar=True):
    '''
    ncfid : objet dataset netCDF4
    nomvar : nom de variable
    renvoie le contenu de l'attribut long_name s'il existe, sinon renvoie nomvar
    '''
    if hasattr(ncfid.variables[nomvar],'long_name'):
        return ncfid.variables[nomvar].long_name
    else:
        if titre_nomvar:
            return nomvar
        else:
            return None

def unit_champ(ncfid,nomvar):
    '''
    ncfid : objet dataset netCDF4
    nomvar : nom de variable
    renvoie l'unité du champ s'il existe, sinon ''
    '''
    if hasattr(ncfid.variables[nomvar],'units'):
        return ncfid.variables[nomvar].units
    else:
        return None

def list_date(datedeb,datefin,delta):
    '''
    delta : de type timedelta
    renvoie une liste de dates comprises entre datedeb et datefin tous les delta (avec origine datedeb 0h)
    '''
    from datetime import datetime
    list=[]
    datecour=datetime(datedeb.year,datedeb.month,datedeb.day,0,0,0)
    while datecour <= datefin:
        if datecour >= datedeb and datecour <= datefin:
            list.append(datecour)
        datecour+=delta
    return list   

def list_dateyear(datedeb,datefin):
    '''
    renvoie une liste des 1er janvier des années comprises entre datedeb et datefin
    '''
    from datetime import datetime
    list=[]
    yeardeb=datetime(datedeb.year,1,1,0,0,0)
    yearcour=yeardeb

    while yearcour <= datefin:
        if yearcour >= datedeb and yearcour <= datefin:
            list.append(yearcour)
        yearcour=datetime(yearcour.year+1,1,1,0,0,0)
    return list   

def list_datemois(datedeb,datefin):
    '''
    renvoie une liste des 1er jours du mois pour les dates comprises entre datedeb et datefin
    '''
    from datetime import datetime
    from dateutil.relativedelta import relativedelta
    list=[]
    datecour=datetime(datedeb.year,datedeb.month,1,0,0,0)
    while datecour <= datefin:
        if datecour >= datedeb and datecour <= datefin:
            list.append(datecour)
        datecour=datecour+relativedelta(months=+1)
    return list   


def pos_tick_date(ax,datedeb,datefin,delta_labinf=timedelta(days=1),rotation_lab=0):
    '''
    position et label des ticks axe x avec date
    ajoute un label de date sous l'axe de temps avec les dates renvoyées par la fonction list_date
    '''
    from matplotlib import dates
    from datetime import datetime
    from datetime import timedelta
    import matplotlib.ticker as ticker

    date_range=datefin-datedeb

    # ticks axe x
    #-------------
    # - ticks majeurs 
    # position et format des labels automatiques
    #if ( date_range < timedelta(days = 5) or date_range > timedelta(days = 100) ):

    if ( date_range < timedelta(days = 5) or date_range > timedelta(days = 160) ):
        # cas >150j : pour que le mois de janvier soit toujours affiché car on met aussi un label dessous avec l'année
        choix_interv=True
    else:
        # cas où il y a des labels avec des jours dans le mois, il faut mettre False
        # pour avoir toujours des intervalles de même largeur entre 2 ticks majeurs, sinon il y a un intervalle irrégulier en fin de mois
        choix_interv=False
    xlocator=dates.AutoDateLocator(interval_multiples=choix_interv)
    #xlocator=dates.AutoDateLocator()
    xlocator.intervald[dates.HOURLY] = [1,3,6,12] # pour modifier la liste des choix d'intervalle d'heures
    xlocator.intervald[dates.DAILY] = [1,2,3,4,5,6,8,10,14] # intervalles défaut si comptés en jours
    xformatter=dates.AutoDateFormatter(xlocator)
    # modif des formats à utiliser dans le dictionnaire scaled
    # (fonction de la distance en jour entre 2 ticks majeurs)
    xformatter.scaled[30.]= '%b'
    xformatter.scaled[1.]= '%d'
    xformatter.scaled[1./24.]= '%H:%M'
    xformatter.scaled[1./(24.*60.)]='%H:%M'

    # position aux jours du mois indiqué et un format particulier précisé
    #else:
        #xlocator=dates.DayLocator(bymonthday=[1,5,10,15,20,25])
    #    xlocator=dates.DayLocator(bymonthday=[1,15])
    #    xformatter=dates.DateFormatter('%d')

    if ( rotation_lab != 0 ):
        ax.set_xticklabels(ax.xaxis.get_majorticklabels(), rotation=rotation_lab)
    ax.xaxis.set_major_locator(xlocator)
    ax.xaxis.set_major_formatter(xformatter)

    # - ticks mineurs éventuels
    # position en fonction de date_range : toutes les 30' ou toutes les heures ou toutes les 6 heures ou tous les jours ou tous les mois ou pas de ticks
    nbday_limit=1800
    avectick_mineur=False
    if ( date_range < timedelta(days = 3) ):
        avectick_mineur=True
        # tick toutes les heures
        if ( date_range > timedelta(hours = 12) ):
            xlocator_minor=dates.HourLocator()
        # tick toutes les 30'
        else:
            xlocator_minor=dates.MinuteLocator(interval=30)
    else:
        # tick toutes les 6h
        if ( date_range < timedelta(days = 12) ):
            avectick_mineur=True
            xlocator_minor=dates.HourLocator(interval=6)
        else:
            # tick tous les jours
            if ( date_range < timedelta(days = 70) ):
                avectick_mineur=True
                xlocator_minor=dates.DayLocator()
            else:
                # tick tous les mois
                if ( date_range < timedelta(days = nbday_limit ) ):
                    avectick_mineur=True
                    xlocator_minor=dates.MonthLocator()

    if (avectick_mineur):
        ax.xaxis.set_minor_locator(xlocator_minor)

    # on met des labels sous certains ticks mineur
    # liste des labels mineurs à écrire
    nblab=0
    limit_nbj_unlabel_parmois=160
    limit_nbj_unlabel_tousles_njours=5
    if ( date_range < timedelta(days = limit_nbj_unlabel_tousles_njours ) ):
        listdatelab=list_date(datedeb,datefin,delta_labinf)
    else:
        if ( date_range < timedelta(days = limit_nbj_unlabel_parmois) ):
            # label le 1er jour de chaque mois 
            listdatelab=list_datemois(datedeb,datefin)
        else:
            # label le 1er jour de chaque année 
            listdatelab=list_dateyear(datedeb,datefin)
    #print 'listdatelab=',listdatelab


    if ( date_range < timedelta(days = nbday_limit) ):
        # fonction pour mettre un label à des dates particulières 
        labdessous={}
        for d in listdatelab:
            dstr=d.strftime('%Y-%m-%d %H:%M:%S')
            if ( date_range < timedelta(days = limit_nbj_unlabel_tousles_njours ) ):
                labdessous[dstr]=d.strftime('%d %b %Y')
            else:
                if ( date_range < timedelta(days = limit_nbj_unlabel_parmois) ):
                    labdessous[dstr]=d.strftime('%b %Y')
                else:
                    labdessous[dstr]=d.strftime('%Y')

        #print 'labdessous=',labdessous

        # fonction de formatage des labels en fonction des valeurs de tick 
        # renvoie un label si le tick correspond à une des clés du dico labdessous
        # ça marche mais pas compris pouquoi les ticks sont parcourus 2 fois (pour l'axe supérieur du graphique ?)
        def format_fn(tick_val, tick_pos):
            #print 'tick_val=',tick_val
            #print 'tick_pos=',tick_pos
            tick_val_str=dates.num2date(tick_val).strftime('%Y-%m-%d %H:%M:%S')
            #print 'tick_val_str=',tick_val_str
            if tick_val_str in labdessous:
                #print 'labdessous=',labdessous[tick_val_str]
                return labdessous[tick_val_str]
            else:
                return ''

        # appel de la fonction de formatage des labels pour les ticks mineurs
        ax.xaxis.set_minor_formatter(ticker.FuncFormatter(format_fn))
        # espacement entre l'axe et le label de tick
        # permet de décaler les labels mineurs
        ax.xaxis.set_tick_params(which='minor',pad=12,labelsize=12)

    # ticks vers l'extérieur
    ax.xaxis.set_tick_params(which='both',direction='out')

    # ticks mineurs plus long quand affichage MMM YYYY ou YYYY 
    if ( date_range > timedelta(days = 70) ):
        ax.xaxis.set_tick_params(which='minor',length=4,top=False)

    nblab=len(listdatelab)

    return nblab 

def crea_ferret_default():
    '''
    palette aux couleurs ferret default pour matplotlib
    '''
    import matplotlib as mpl

    cdict = {'red': ((0.0,  0.0, 0.8),
                     (0.1,  0.3, 0.3),
                     (0.33, 0.0, 0.0),
                     (0.66, 1.0, 1.0),
                     (0.9,  1.0, 1.0),
                     (1.0,  0.6, 1.0)),

           'green': ((0.0,  0.0, 0.0),
                     (0.1,  0.2, 0.2),
                     (0.33, 0.6, 0.6),
                     (0.66, 1.0, 1.0),
                     (0.9,  0.0, 0.0),
                     (1.0,  0.0, 0.0)),

           'blue':  ((0.0,  0.0, 1.0),
                     (0.1,  1.0, 1.0),
                     (0.33, 0.3, 0.3),
                     (0.66, 0.0, 0.0),
                     (1.0,  0.0, 0.0))}

    return mpl.colors.LinearSegmentedColormap('ferret_default', cdict, N=256, gamma=1.0)
