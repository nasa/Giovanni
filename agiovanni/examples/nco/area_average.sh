#!/bin/bash -x
ncap2 -O -s '*d2r=acos(-1.)/180.; coslat=cos(lat*d2r)' in.nc in+coslat.nc
ncwa -O -a lat,lon -w coslat in+coslat.nc area_average.nc
