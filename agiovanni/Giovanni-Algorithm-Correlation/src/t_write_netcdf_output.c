/*
 * NAME  
 *   t_write_netcdf_output - unit test for nccorrelate/write_netcdf_output.c
 *
 * SYNOPSIS
 *   t_write_netcdf_output
 *
 * DESCRIPTION
 *   Runs the accumulate() function for 3 pairs of files, and
 *   compares a few of the output numbers using assert.
 *
 * FILES 
 *   t_write_netcdf_output.nc (generated from CDL) is the reference
 *   file and is compared against the output file t_out.nc
 *
 * AUTHOR
 *   Chris Lynnes
 *
 * $Id: t_write_netcdf_output.c,v 1.8 2013/07/05 00:43:48 clynnes Exp $ 
 * -@@@ Giovanni, Version $Name:  $
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "netcdf.h"
#include "nccorrelate.h"


int main(int argc, char **argv)
{
  /* Declare and initialize */
  char *outfile = "t_write_netcdf_output.nc";
  char *outpath, *outdir;
  char *compare_file, *cmd;
  int nlat = 3;
  int nlon = 2;
  int rc;
  int n_samples[] = {6,5,4,3,2,1};
  double correlation_fill = -2.;
  double correlation[] = {-1.0,-0.5,0.,correlation_fill,0.5,1.0};
  double slope_fill = -999.;
  double slope[] = {-1.0,-0.5,0.,slope_fill,0.5,1.0};
  double offset_fill = -99999.;
  double offset[] = {-2.5,-1.5,0.,offset_fill,1.5,2.5};
  double diff_fill = -99999.;
  double diff[] = {diff_fill,diff_fill,diff_fill,diff_fill,diff_fill,diff_fill};
  double sum_x[] = {diff_fill,diff_fill,diff_fill,diff_fill,diff_fill,diff_fill};
  double sum_y[] = {diff_fill,diff_fill,diff_fill,diff_fill,diff_fill,diff_fill};
  double lat[] = {10.,20.,30.};
  double lon[] = {40.,60.};

  outdir = getenv("TMPDIR");
  if (outdir == NULL) outdir = strdup(".");
  outpath = malloc(strlen(outdir)+strlen(outfile)+2);
  sprintf(outpath, "%s/%s", outdir, outfile);

  /* Write reference file first so we don't clobber output */
  compare_file = cdl2nc("t_write_netcdf_output.cdl" , "t_write_netcdf_output_ref.nc");

  /* Write netCDF output file */
  write_netcdf_output(2, outpath, nlat, nlon, n_samples, 
    correlation, correlation_fill, slope, slope_fill, offset, offset_fill, 
    diff, diff_fill,
    sum_x, sum_y, NULL, NULL, NULL, lat, lon);

  /* Compare the reference file (compare_file) with the output file */
  cmd = malloc(strlen(compare_file) + strlen(outpath) + 6);
  sprintf(cmd, "diff %s %s", compare_file, outpath);
  fprintf(stderr, "INFO executing %s\n", cmd);
  rc = system(cmd);
  if (rc != 0) {
    fprintf(stderr, "Output and test reference files do not match\n");
  }
  /* clean up */
  else if (getenv("SAVE_TEST_FILES") == NULL) {
    unlink(compare_file);
    unlink(outpath);
  }

  /* Exit with the error code from the diff */
  exit(rc >> 8);
}
