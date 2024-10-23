#!/bin/bash

# use bash change_time.sh file.nc number

#ncap2 -O -s 'defdim("time",-25);time[time]={1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25};time@long_name="time";time@units="hours since 2009-12-11 00:00"' -O $1 newtime_$1.nc

cp $1 tmp.nc
ncap2 -s 'time={0.5,1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5,9.5,10.5,11.5,12.5,13.5,14.5,15.5,16.5,17.5,18.5,19.5,20.5,21.5,22.5,23.5} ; time@units="hours since 2009-12-11 00:00:00" ; time@calendar="gregorian" ' tmp.nc

mv tmp.nc newtime_LES$2.nc

