### Exemple : on veut plotter que pour les métriques 3D
# -o pour specifier les obs
# -e pour les fichiers de metriques
# -p pour les fichiers de parametres (uniquement pour scatter_param_metric.py)
# pour scatter_metric_metric.py et scatter_param_metric.py la recher des bests n'est pas automatisée dans ce cas, il faut les specifier à la main avec l'option -b
# -l pour spécifier les ensemble que l'on veut mettre en couleur (sinon tout en gris) pour
#    scatter_param_metric.py et scatter_metric_metric.py

path=ImportedMetrics

python scatter_score.py -o ${path}/obs.csv -e ${path}/metrics_41.csv,${path}/metrics_42.csv

python scatter_metric_metric.py -o ${path}/obs.csv -e ${path}/metrics_41.csv,${path}/metrics_42.csv -l ${path}/metrics_41.csv -b SCM-41-056,SCM-42-038

python scatter_param_metric.py -o ${path}/obs.csv -e ${path}/metrics_41.csv,${path}/metrics_42.csv -p WAVE41/Par1D_Wave41.asc,WAVE42/Par1D_Wave42.asc -l ${path}/metrics_41.csv -b SCM-41-056,SCM-42-038

### Pour le 1D : 
#pour les vagues 1D ou pour les fichiers et dossier respectant le format et l'architecture tuning, on peut specifier dans les codes python les vagues min et max que l'on souhaite plotteret lancer sans options (ça va chercher les bests tout seul à partir des scoreXX.csv)

#Maelle Mars 2024
