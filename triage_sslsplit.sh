#!/bin/bash

#################################################
#						#
#		But du script :			#
#	récupérer un max de datas à stocker	#
#	On prend les requêtes :			#
#	POST,GET with JS,EXE,.ZIP,.tar.gz	#
#						#
#################################################

SSLSPLIT_LOG_PATH=/tmp/sslsplit/logdir
SSLSPLIT_LOGROTATE=/tmp/sslsplit/logrotate
HERE=$(pwd)
SSLSPLIT_SOURCE_LOGS=/tmp/sslsplit/logrotate/outputs/sourcelog
DATE=`date +"%d-%m-%Y_%H-%M"`

##### Création du dossier à backuper ######
mkdir $SSLSPLIT_SOURCE_LOGS/$DATE
mkdir $SSLSPLIT_SOURCE_LOGS/$DATE/POST
mkdir $SSLSPLIT_SOURCE_LOGS/$DATE/ZIP

##### On se met dans le bon répertoire #####
cd $SSLSPLIT_LOGROTATE

#On créé un fichier temporaire pour pouvoir travailler que sur un bundle de fichier qu'on pourra effacer à la fin pour garder de l'espace.
array=($(ls /tmp/sslsplit/logdir))
for ((i=0; i<${#array[@]}; i++))
	do
		echo ${array[$i]} >> $SSLSPLIT_LOGROTATE/TEMP_LIST.txt
	done


######### DEBUT - SECTION DE TRAITEMENT DES REQUETES POST ##########
#  Récupérer tous les files dont la premiere ligne commence par POST
#awk 'FNR==1{if ($0~"POST") pri:wqnt FILENAME;}' /tmp/sslsplit/logdir/*.log > $SSLSPLIT_LOGROTATE/POST_DATAS.files
array=($(cat $SSLSPLIT_LOGROTATE/TEMP_LIST.txt))
for ((i=0; i<${#array[@]}; i++))
	        do
			awk 'FNR==1{if ($0~"POST") print FILENAME;}' $SSLSPLIT_LOG_PATH/${array[$i]} >> $SSLSPLIT_LOGROTATE/POST_DATAS.files
		done


array=($(cat $SSLSPLIT_LOGROTATE/POST_DATAS.files))
for ((i=0; i<${#array[@]}; i++))
	        do
			FILENAME_TIME=$(echo ${array[$i]} | awk -F "/" '{print $5}' | awk -F "-" '{print $1}')
			FILENAME=$(echo ${array[$i]} | awk -F "/" '{print $5}')
			head -n 2 ${array[$i]} | tr '\r\n' ' ' | awk '{OFS ="\";\""} {print "\"""'$FILENAME_TIME'",$1,$5,$2,"'$FILENAME'""\""}' >> $SSLSPLIT_LOGROTATE/POST_DATAS.log
			cp ${array[$i]} $SSLSPLIT_SOURCE_LOGS/$DATE/POST
		done

######### FIN - SECTION DE TRAITEMENT DES REQUETES POST ###########		

######### DEBUT - SECTION DE TRAITEMENT DES REQUETES GET - FILE ZIP ##########

array=($(cat $SSLSPLIT_LOGROTATE/TEMP_LIST.txt))
for ((i=0; i<${#array[@]}; i++))
	do
		grep -l -ab "\.zip HTTP\/" $SSLSPLIT_LOG_PATH/${array[$i]} >> $SSLSPLIT_LOGROTATE/ZIP.files
	done

cd $SSLSPLIT_LOGROTATE
array=($(cat $SSLSPLIT_LOGROTATE/ZIP.files))
for ((i=0; i<${#array[@]}; i++))
	do
		FILENAME_TIME=$(echo ${array[$i]} | awk -F "/" '{print $5}' | awk -F "-" '{print $1}')
		FILENAME=$(echo ${array[$i]} | awk -F "/" '{print $5}')
		HOST_ZIP=$(grep "\.zip HTTP\/" ${array[$i]} -ab -A 1 | tail -1 | awk -F ":" '{print $2}'| tr -d '\r' | tr -d ' ')
		ZIP_GET=$(grep "\.zip HTTP\/" ${array[$i]} -ab -A 1 | head -n1 | awk -F ":" '{print $2}' | awk '{print $2}')
		echo "\"$FILENAME_TIME\";\"ZIP\";\"$HOST_ZIP\";\"$ZIP_GET\";\"$FILENAME\"" >> $SSLSPLIT_LOGROTATE/ZIP_DATAS.log
		cp ${array[$i]} $SSLSPLIT_SOURCE_LOGS/$DATE/ZIP 		

		# Récupération du zip via foremost
		foremost -t zip ${array[$i]} 2&> /dev/null
		mkdir $SSLSPLIT_LOGROTATE/outputs/zip/$FILENAME
		mv ./output/zip/* $SSLSPLIT_LOGROTATE/outputs/zip/$FILENAME
		rm -rf $SSLSPLIT_LOGROTATE/output
	done

######### FIN - SECTION DE TRAITEMENT DES REQUETES GET - FILE ZIP ##########

######### DEBUT - SECTION DE TRAITEMENT DES REQUETES GET - FILE EXE ##########


######### Effacement des fichiers inutiles ###########
#array=($(cat $SSLSPLIT_LOGROTATE/TEMP_LIST.txt))
#for ((i=0; i<${#array[@]}; i++))
        #do
		#rm $SSLSPLIT_LOG_PATH/${array[$i]}
	#done


#### ON EFFACE LES FICHIERS TEMPORAIRES ####
rm -rf $SSLSPLIT_LOGROTATE/ZIP.files
rm -rf $SSLSPLIT_LOGROTATE/POST_DATAS.files
rm -rf $SSLSPLIT_LOGROTATE/TEMP_LIST.txt
