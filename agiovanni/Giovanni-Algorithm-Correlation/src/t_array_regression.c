/*
 * NAME  
 *   t_array_regression - unit test for nccorrelate/array_regression.c
 *
 * SYNOPSIS
 *   t_array_regression
 *
 * DESCRIPTION
 *   Runs the array_regression() function for a 3 element array.
 *   Compares a few of the output numbers to within tolerance using check().
 *
 * AUTHOR
 *   Chris Lynnes
 *
 * $Id: t_array_regression.c,v 1.5 2013/03/19 16:45:18 jpan Exp $ 
 * -@@@ Giovanni, Version $Name:  $
 */

#include <stdio.h>
#include <stdlib.h>
#include "nccorrelate.h"
#define FILL -999.0

int main(int argc, char **argv)
{
  double sum_x2[] = {14.,14.,  16.};
  double sum_y2[] = {16.,35.31,35.31};
  double sum_x[]  = { 6., 6.,   8.};
  double sum_y[]  = { 8.,10.70,10.70};
  double sum_xy[] = {12.,21.80,21.40};
  double correct_slope[] = {FILL, 1.15, FILL};
  double correct_offset[] = {2., 0.95, FILL};
  double correct_correlation[] = {FILL, 0.9944, FILL};
  int n[]  = {4, 4, 4};
  int i, err = 0;
  int status;
  double correlation[3], slope[3], offset[3], diff[3]; 
  
  err += check(t_statistic(119, 0.95), 1.658, .0005, "T(119)");
  err += check(t_statistic(61, 0.95), 1.671, .0005, "T(61)");
  err += check(t_statistic(1, 0.95), 6.314, .0005, "T(1)");
  err += check(t_statistic(2, 0.95), 2.920, .0005, "T(2)");
  err += check(t_statistic(120, 0.95), 1.658, .0005, "T(120)");
  err += check(t_statistic(2000000, 0.95), 1.645, .0005, "T(120)");

  array_regression (3, sum_x2, sum_y2, sum_xy, sum_x, sum_y, n, 
    correlation, FILL, slope, FILL, offset, FILL, diff, FILL);
  for (i = 0; i < 3; i++) {
    printf("Slope=%9.4lf  Offset=%9.4lf  R=%9.4lf\n", slope[i], offset[i], correlation[i]);
    status = check(slope[i], correct_slope[i], 0.001, "Slope");
    err += status;
    status = check(offset[i], correct_offset[i], 0.001, "Offset");
    err += status;
    status = check(correlation[i], correct_correlation[i], 0.001, "Correlation");
    err += status;
  }
  if (err == 0) fprintf(stderr, "A-OK!\n");
  else fprintf(stderr, "%d errors\n", err);
  
  exit(err);
}
