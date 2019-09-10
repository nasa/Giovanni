/*
 * NAME
 *   accumulate - accumulate statistical sums for linear regression
 *
 * SYNOPSIS
 *   void accumulate(
 *     int verbose,     # Pass-through to functions to control debug output
 *     int n,           # Number of points in each array
 *     char **files,    # Pair of input filenames
 *     long epoch,      # If doing time regression, specify anchor epochal time
 *                      #  A value < 0 indicates this is a var x var regression
 *     char *vars[],    # Pair of input variable names
 *     size_t **starts, # Pair of start[] arrays for subsetting netcdf
 *     size_t **counts, # Pair of count[] arrays for subsetting netcdf
 *     double *sum_x2,  # Sum of x**2
 *     double *sum_y2,  # Sum of y**2
 *     double *sum_xy,  # Sum of x * y
 *     double *sum_x,   # Sum of x
 *     double *sum_y,   # Sum ov y
 *     int *nsamples    # Number of samples
 *   )
 *
 * DESCRIPTION
 *   accumulate adds the values from the current pair of files to the
 *   various sum_* arrays, i.e., for each grid cell.  It also increments 
 *   the nsamples array. N.B.:  If EITHER array has a fill value in a
 *   given grid cell, the sum/nsamples will not be summed/incremented for
 *   that grid cell.
 *
 *   All arrays passed in the calling arguments are assumed to have been
 *   allocated (and initialised).
 *
 * AUTHOR
 *  Chris Lynnes, NASA/GSFC
 *
 * $Id: accumulate.c,v 1.8 2013/07/05 00:43:48 clynnes Exp $ 
 * -@@@ Giovanni, Version $Name:  $
 */
#include <stdlib.h>
#include <stdio.h>
#include "netcdf.h"
#include "nccorrelate.h"

double get_time (int ncid, char *file, int epoch);

void accumulate(int verbose, int n, char **files, long epoch, char *vars[], 
  size_t **starts, size_t **counts,
  double *sum_x2, double *sum_y2, double *sum_xy, double *sum_x, double *sum_y, int *nsamples)
{
  int i, ncid[2], varid, status, nread, n_files;
  double *dvars[2] = {NULL, NULL};
  double x, y, years;
  double fill[2];
  char *varname, *p;

  /* Need two files unless we are regressing against time */
  /* in which case, we extract time from the first and only file */
  n_files = (epoch < 0) ? 2 : 1;

  /* Foreach file... */
  for (i = 0; i < n_files; i++) {
    if ((status = nc_open(files[i], NC_NOWRITE, ncid+i)) != NC_NOERR) {
      fprintf(stderr, "ERROR failed to open netcdf file %s: %d %s\n", files[i], status, nc_strerror(status));
      exit(3);
    }

    /* Look for the variable by name (from vars[]) */
    /* Strip off z dimension if there */
    varname = strdup(vars[i]);
    p = strchr(varname , ',');
    if (p) *p = '\0';
    
    if ((status = nc_inq_varid(ncid[i], varname, &varid)) != NC_NOERR) {
      fprintf(stderr, "ERROR failed to get varid for variable %s in file %s: %d %s",
        vars[i], files[i], status, nc_strerror(status));
      exit(-status);
    }

    /* Read in the variable values */
    if ((nread = read_nc_var(verbose, ncid[i], varid, starts[i], counts[i], dvars+i, fill+i)) != n) {
      fprintf(stderr, "ERROR failed to read in variable %s from file %s: n=%d nread=%d\n",
        varname, files[i], n, nread);
      exit(-1);
    }
    if (epoch >= 0) {
      years = get_time(ncid[i], files[i], epoch);
      /* We actually want time on the x axis, so swap fill positions */
      fill[1] = fill[0];
      fill[0] = -1.;
    }
    ncclose(ncid[i]);
    free(varname);
  }
  /* TODO:  handle case where the dimension indexes are reversed */
  /* Compute sums */
  for (i = 0; i < n; i++) {
    if (epoch < 0) {
      x = dvars[0][i];
      y = dvars[1][i];
    }
    /* Want to put time on the X axis */
    else {
      x = years;
      y = dvars[0][i];
    }
    if (x != fill[0] && y != fill[1]) {
      sum_x2[i] += x * x;
      sum_y2[i] += y * y;
      sum_xy[i] += x * y;
      sum_x[i] += x;
      sum_y[i] += y;
      nsamples[i]++;
    }
    if (verbose >= 4) {
      fprintf(stderr, "DEBUG sums: %4d %4d %7.2f %7.2f %7.2f %7.2f %7.2f\n",
        i, nsamples[i], sum_x[i], sum_y[i], sum_x2[i], sum_y2[i], sum_xy[i]);
    }
  }
  /* Free memory to avoid memory leak */
  free(dvars[0]);
  if (epoch < 0) free(dvars[1]);
}
double get_time (int ncid, char *file, int epoch)
{
  int status, varid;
  size_t start[] = {0};
  int time;
  if ((status = nc_inq_varid(ncid, "time", &varid)) != NC_NOERR) {
    fprintf(stderr, "ERROR failed to get varid for time in file %s: %d %s",
      file, status, nc_strerror(status));
    exit(-status);
  }
  if ((status = nc_get_var1_int(ncid, varid, start, &time)) != NC_NOERR) {
      fprintf(stderr, "ERROR failed to read in time from file %s: %d %s",
        file, status, nc_strerror(status));
      exit(-status);
  }
  return ((time - epoch) / (3600. * 24. * 365.25));
}
