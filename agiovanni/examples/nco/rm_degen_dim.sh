#!/bin/bash -x
ncwa -O -C -x -v time -a time in.nc no_degen_dim.nc
ncatted -a 'coordinates,AIRX3STD_006_CloudTopTemp_A,o,c,lat lon' -O no_degen_dim.nc
