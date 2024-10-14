#!/bin/bash

INFILE=$1
OUTFILE=$2
shift
shift

echo Scaling profiles from $INFILE

nccopy -3 $INFILE tmp.nc

while [ "$1" ]
do
    FOUND=$(echo $1 | grep '=')
    if [ ! "$FOUND" ]
    then
    	echo "Error in $0: argument '$1' not of the form key=value"
    	exit 1
    fi
    KEY=$(echo $1 | awk -F= '{print $1}')
    KEY=${KEY:6}
    VALUE=$(echo $1 | awk -F= '{print $2}')
    FOUND=$(ncdump -h $INFILE | grep $KEY)
    if [ ! "$FOUND" ]
    then
	    echo "Error: $KEY not found in $INFILE"
	    exit 1
    fi
    ncap2 -O -A -s "$KEY=$VALUE*$KEY" tmp.nc
    if [ $KEY == overlap_param ] 
    then 
      ncap2 -O -A -s "where($KEY>1) $KEY=1" tmp.nc
    fi
    shift
done

nccopy tmp.nc $OUTFILE
rm tmp.nc
