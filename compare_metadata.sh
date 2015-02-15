# Created by kedziorm
#script to ensure that metadata in BEC soil moisture data are exactly the same in all files
# (Slope=1 and Intercept=0)

for d in */*1deg; do

	echo "$d"
	m=$(gdalinfo "$d" |egrep -wc 'Slope=1')
	n=$(gdalinfo "$d" |egrep -wc 'Intercept=0')
	#echo "m is equal " $m
	#echo "n is equal " $n

	if [ "$n" != '1' ]; then 
		echo "Slope for file " $d " is different than 1"
	fi

	if [ "$m" != '1' ]; then 
		echo "Intercept for file " $d " is different than 0"
	fi

 done
