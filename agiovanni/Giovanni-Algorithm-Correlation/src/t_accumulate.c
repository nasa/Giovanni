/*
 * NAME 
 *   t_accumulate - unit test for nccorrelate/accumulate.c
 *
 * SYNOPSIS
 *   t_accumulate
 *
 * DESCRIPTION
 *   Runs the accumulate() function for 3 pairs of files, and 
 *   compares a few of the output numbers using assert.
 *
 * FILES
 *   t_accumulate_[1-3]{a,b}
 *
 * AUTHOR
 *   Chris Lynnes
 *
 * $Id: t_accumulate.c,v 1.5 2013/07/05 00:43:48 clynnes Exp $ 
 * -@@@ Giovanni, Version $Name:  $
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "netcdf.h"
#include "nccorrelate.h"
#define NTIME 1
#define NLAT 8
#define NLON 3
#define NPTS (NTIME*NLAT*NLON)
#define NSTEPS 3
#define VERBOSE 3

int main(int argc, char **argv)
{
  int i, j, npts, status, ncid, varid;
  double fill, *values;
  char *varnames[2] = {"Optical_Depth_Land_And_Ocean_Mean", "Optical_Depth_Land_And_Ocean_Mean"};
  char *filepair[2], *basename;
  int nsamples[NPTS];
  size_t **starts, **counts;
  double sum_x2[NPTS], sum_y2[NPTS], sum_xy[NPTS], sum_x[NPTS], sum_y[NPTS];

  starts = malloc(2 * sizeof(size_t *));
  counts = malloc(2 * sizeof(size_t *));
  for (i = 0; i < 2; i++) {
    starts[i] = malloc(3 * sizeof(size_t));
    starts[i][0] = 0;
    starts[i][1] = 0;
    starts[i][2] = 0;
    counts[i] = malloc(3 * sizeof(size_t));
    counts[i][0] = NTIME;
    counts[i][1] = NLAT;
    counts[i][2] = NLON;
  }
  /* Initialize arrays */
  for (i = 0; i < NPTS; i++) {
    sum_x2[i] = 0.;
    sum_y2[i] = 0.;
    sum_xy[i] = 0.;
    sum_x[i] = 0.;
    sum_y[i] = 0.;
    nsamples[i] = 0;
  }

  basename = malloc(strlen(argv[0]) + 9);

  /* File pattern is t_accumulate_1a.nc, t_accumulate_1b.nc, etc. */
  for (i = 0; i < NSTEPS; i++) {

    sprintf(basename, "%s_%da.cdl", argv[0], i+1);
    filepair[0] = cdl2nc(basename, NULL);

    sprintf(basename, "%s_%db.cdl", argv[0], i+1);
    filepair[1] = cdl2nc(basename, NULL);

    accumulate(VERBOSE, NPTS, filepair, -1, varnames, starts, counts, 
      sum_x2, sum_y2, sum_xy, sum_x, sum_y, nsamples);

    unlink(filepair[0]);
    unlink(filepair[1]);
  }

  for (i = 0; i < NLAT; i++) {
    j = i*NLON;
    printf("%d %d %d|", nsamples[j], nsamples[j+1], nsamples[j+2]);
    printf("%4.2f %4.2f %4.2f|", sum_x2[j], sum_x2[j+1], sum_x2[j+2]);
    printf("%4.2f %4.2f %4.2f|", sum_y2[j], sum_y2[j+1], sum_y2[j+2]);
    printf("%4.2f %4.2f %4.2f|", sum_x[j], sum_x[j+1], sum_x[j+2]);
    printf("%4.2f %4.2f %4.2f|", sum_y[j], sum_y[j+1], sum_y[j+2]);
    printf("%4.2f %4.2f %4.2f", sum_xy[j], sum_xy[j+1], sum_xy[j+2]);
    printf("\n");
  }
  assert(nsamples[0] == 0);
  assert(nsamples[1] == 1);
  assert(nsamples[2] == 2);

  assert(sum_x[3] == 1.425);
  assert(sum_y[3] == 1.425);
  assert((sum_x2[3]-0.676875) < .000001);
  assert((sum_y2[3]-0.676875) < .000001);
  assert((sum_xy[3]-0.676875) < .000001);

  /* assert will quit for us if no matches */
  exit(0);
}
