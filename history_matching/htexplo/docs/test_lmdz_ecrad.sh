# lancer ce script pour tester LMDZ+ECRAD
# REFLIQ = forcer les re_liquid de LMDZ à 10 microns comme dans les refs MC
wdir=ECRAD_LMDZ_SANDU
bash bench.sh -metrics SANDU_REF_neb4zave_50_60,RAD_SANDU_REF008_unt_01_01,RAD_SANDU_REF008_unt_05_05,RAD_SANDU_REF008_unt_08_08,RAD_SANDU_REF012_unt_01_01,RAD_SANDU_REF012_unt_05_05,RAD_SANDU_REF012_unt_08_08 -sample_size_next_design 70 -param param_ArtII2_avec_ecrad -wdir $wdir -waves "`seq 1 9`"

exit

# avec toutes les métriques de ArtII1 et des métriques de rayonnement
wdir=TEST_ECRAD_ARMCU_ArtII_3SZA_REFLIQ_MOREMETS
./bench.sh -metrics ARMCU_REF_zav-400-600-theta_7_9,ARMCU_REF_zav-400-600-qv_7_9,ARMCU_REF_nebmax_7_9,RICO_REF_nebmax_19_25,SANDU_REF_neb4zave_50_60,RAD_ARMCU_REF008_unt_01_01,RAD_ARMCU_REF008_unt_05_05,RAD_ARMCU_REF008_unt_08_08,RAD_ARMCU_REF012_unt_01_01,RAD_ARMCU_REF012_unt_05_05,RAD_ARMCU_REF012_unt_08_08,RAD_RICO_REF005_unt_01_01,RAD_RICO_REF005_unt_05_05,RAD_RICO_REF005_unt_08_08,RAD_RICO_REF007_unt_01_01,RAD_RICO_REF007_unt_05_05,RAD_RICO_REF007_unt_08_08 -sample_size_next_design 70 -param param_ArtII1_avec_ecrad -wdir $wdir -waves "`seq 1 9`"


wdir=TEST_ECRAD_ARMCU_ArtII_3SZA_REFLIQ
./bench.sh -metrics "ARMCU_REF_zav-400-600-theta_7_9 ARMCU_REF_zav-400-600-qv_7_9 RAD_ARMCU_REF008_uptoa_01_01 RAD_ARMCU_REF008_uptoa_05_05 RAD_ARMCU_REF008_uptoa_08_08 ARMCU_REF_nebmax_7_9" -sample_size_next_design 60 -param param_ArtII1_avec_ecrad -wdir $wdir -waves "`seq 1 9`"

exit

wdir=TEST_ECRAD_ARMCU_ArtII_3SZA
./bench.sh -metrics "ARMCU_REF_zav-400-600-theta_7_9 ARMCU_REF_zav-400-600-qv_7_9 RAD_ARMCU_REF008_uptoa_01_01 RAD_ARMCU_REF008_uptoa_05_05 RAD_ARMCU_REF008_uptoa_08_08 ARMCU_REF_nebmax_7_9" -sample_size_next_design 60 -param param_ArtII1_avec_ecrad -wdir $wdir -waves "`seq 1 9`"

wdir=TEST_ECRAD_ARMCU_ArtII
./bench.sh -metrics "ARMCU_REF_zav-400-600-theta_7_9 ARMCU_REF_zav-400-600-qv_7_9 RAD_ARMCU_REF008_uptoa_01_01 ARMCU_REF_nebmax_7_9" -sample_size_next_design 60 -param param_ArtII1_avec_ecrad -wdir $wdir -waves "`seq 1 9`"

exit 

wdir=TEST_ECRAD_ARMCU
./bench.sh -metrics "RAD_ARMCU_REF008_uptoa_01_01 ARMCU_REF_nebmax_7_9" -sample_size_next_design 60 -param param_avec_ecrad -wdir $wdir -waves "`seq 1 9`"

exit 

wdir=TEST_ECRAD
./bench.sh -metrics "RAD_RICO_REF005_uptoa_01_01 RICO_REF_nebmax_19_25" -sample_size_next_design 60 -param param_avec_ecrad -wdir $wdir -waves "`seq 1 9`"
