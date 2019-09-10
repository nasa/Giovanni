#!/bin/bash -x
echo Unfortunately, it appears our nco is not built with DAP ':-('
ncks -O -v r -d lat,37.,41. -d lon,-109.05,-102.05 -d time,729391.,729450. http://disc2.nascom.nasa.gov:80/dods/3B43_V7_rainrate gds.nc
