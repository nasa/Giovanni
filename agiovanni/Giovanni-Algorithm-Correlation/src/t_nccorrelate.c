/*
 * NAME
 *   t_nccorrelate - unit test for the nccorrelate executable
 *
 * SYNOPSIS
 *   t_nccorrelate
 *
 * DESCRIPTION
 *   Runs the unit test for the nccorrelate executable. The "answers"
 *   have been checked by manual/spreadsheet calculations.
 *
 *   The procedure is:
 *   1) Convert input files from CDL to netcdf
 *   2) Write the paths to $TMPDIR/filelist.txt 
 *   3) Call nccorrelate
 *   4) Rename the resultant output file to $TMPDIR/t_nccorrelate.nc.cmp*
 *   5) Convert the reference CDL file, t_nccorrelate.cdl, to netcdf.
 *   6) Diff the two files
 *
 *   *This renaming is needed because ncgen names the netCDF "object" in
 *    the netcdf file by the filename, regardless of what it says in the CDL.
 *
 * FILES
 *   Input: e.g., $TMPDIR/MOD08_[1-4].nc, $TMPDIR/MYD08_[1-4].nc
 *   Output: $TMPDIR/t_nccorrelate.nc.cmp
 *   Reference: $TMPDIR/t_nccorrelate.nc
 *
 * AUTHOR
 *   Chris Lynnes
 *
 * $Id: t_nccorrelate.c,v 1.7 2013/07/05 00:43:48 clynnes Exp $
 * -@@@ Giovanni, Version $Name:  $
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <netcdf.h>
#include "nccorrelate.h"

int main(int argc, char **argv) {
  run_nccorrelate_test("t_nccorrelate.cdl",
    "./nccorrelate -v 3 -w -60 -e -58 -s 25 -n 27 -x Optical_Depth_Land_And_Ocean_Mean -y Optical_Depth_Land_And_Ocean_Mean",
    "MOD08_", "MYD08_",
    4, 1,
    "t_correlate.nc"
  );
  run_nccorrelate_test("t_nccorrelate_3d.cdl",
    "./nccorrelate -v 3 -w -148 -e -146 -s 47 -n 49 -x AIRX3STD_006_Temperature_A,TempPrsLvls_A=500hPa -y AIRX3STD_006_Temperature_D,TempPrsLvls_D=500hPa",
    "AIRS_Temp_A.200901", "AIRS_Temp_D.200901",
    3, 17,
    "t_correlate_3d.nc"
  );
  exit(0);
}
