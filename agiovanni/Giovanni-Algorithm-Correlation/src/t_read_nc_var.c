/*
 * NAME  
 *   t_read_nc_var - unit test for nccorrelate/read_nc_var.c
 *
 * SYNOPSIS
 *   t_read_nc_var
 *
 * DESCRIPTION
 *   Reads a variable from a netCDF file into a double array and 
 *   compares a few of the numbers using assert.
 *
 * FILES 
 *   t_read_nc_var.cdl (converted to t_read_nc_var.nc at runtime)
 *
 * AUTHOR
 *   Chris Lynnes
 *
 * $Id: t_read_nc_var.c,v 1.5 2013/07/05 00:43:48 clynnes Exp $ 
 * -@@@ Giovanni, Version $Name:  $
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "netcdf.h"
#include "nccorrelate.h"

int main(int argc, char **argv)
{
  int npts, status, ncid, varid;
  size_t count[3], start[3];
  double fill, *values;
  char *varname = "Optical_Depth_Land_And_Ocean_Mean";
  char *outpath;
  char *ref_file = "t_read_nc_var.cdl";

  outpath = cdl2nc(ref_file, NULL);

  /* Open netCDF file */
  status = nc_open(outpath, NC_NOWRITE, &ncid);
  if (status != NC_NOERR) {
    fprintf(stderr, "ERROR failed to open netcdf file %s: %d\n", outpath, status);
    exit(3);
  }
  if ((status = nc_inq_varid(ncid, varname, &varid)) != NC_NOERR) {
    fprintf(stderr, "ERROR failed to find variable %s in file %s: %d\n",
        varname, outpath, status);
    exit(4);
  }

  /* Read the whole array */
  npts = read_nc_var(2, ncid, varid, NULL, NULL, &values, &fill);
  assert(npts == 114);
  assert(fill == -9.999);
  assert(values[0] == fill);
  assert(values[npts-1] == .377);

  /* Read again, with start and npts set */
  start[0] = 0;
  count[0] = 1;
  start[1] = 35;
  count[1] = 2;
  start[2] = 1;
  count[2] = 2;
  npts = read_nc_var(2, ncid, varid, start, count, &values, &fill);
  assert(npts == (count[0]*count[1]*count[2]));
  assert(values[0] == .626);
  assert(values[npts-1] == .337);


  /* Clean up */
  status = nc_close(ncid);
  unlink(outpath);
  exit(0);
}
