/*
 * NAME
 *   array_regression - simple linear regression for each cell in an array
 *
 * SYNOPSIS
 *   void array_regression (
 *     int n,                   # Number of points in array
 *     double *sum_x2,          # Sum of x**2
 *     double *sum_y2,          # Sum of y**2
 *     double *sum_xy,          # Sum of x * y
 *     double *sum_x,           # Sum of x
 *     double *sum_y,           # Sum of y
 *     int *n_samples,          # Number of samples
 *     double *correlation,     # Correlation coefficient (R)
 *     double correlation_fill, # Fill value for Correlation coefficient (R)
 *     double *slope,           # Slope of regression
 *     double slope_fill,       # Fill value for Slope
 *     double *offset,          # Offset (intercept) of regression
 *     double offset_fill,      # Fill value for offset
 *     double *diff,            # Averaged differences between x and y (x-y)/n
 *     double diff_fill         # Fill value for differences
 *   )
 *
 * DESCRIPTION 
 *   Compute a simple linear regression for each cell in an array, given
 *   arrays of the various sums (x, y, x**2, y**2, x*y).  The equations are:
 *
 *           n * SxSy - Sx * Sy
 *   Slope = -----------------
 *           n * Sxx - Sx ** 2
 *
 *   Offset = (Sy / n) - (slope * Sx / n)
 *
 *       n * SxSy - Sx * Sy
 *   R = -------------------------------------------------
 *       sqrt( (n * Sxx - Sx ** 2) * (n * Syy - Sy ** 2) )
 *
 *   Diff = (Sx - Sy) / n
 *
 * EXCEPTIONS
 *   If all X values are the same, slope will be set to fill value.
 *   If all Y values are the same, offset will be set to fill value.
 *   If slope is fill, then R is fill.
 *   If n < 3, R is fill (not coded as such, but that's how it comes out).
 *
 * SEE ALSO
 *   http://en.wikipedia.org/wiki/Simple_linear_regression
 *
 * AUTHOR
 *  Chris Lynnes, NASA/GSFC
 *
 * $Id: array_regression.c,v 1.7 2013/03/19 16:23:02 jpan Exp $ 
 * -@@@ Giovanni, Version $Name:  $
 */

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "nccorrelate.h"

void array_regression (int n_array, double *sum_x2, double *sum_y2, 
  double *sum_xy, double *sum_x, double *sum_y, int *n_samples, 
  double *correlation, double correlation_fill, double *slope, double slope_fill,
  double *offset, double offset_fill, double *diff, double diff_fill)
{
  int i, n, n_sig;
  double Sx, Sy, SxSy, Sxx, Syy, Sxy, Sx2, Sy2;
  /* Artificial variables just to make underflow/overflow checking easy */
  double x_spread, y_spread;
  double stderr2, threshold, beta, slope_err;

  for (i = 0, n_sig=0; i < n_array; i++) {
    correlation[i] = correlation_fill;
    slope[i] = slope_fill;
    offset[i] = offset_fill;
    diff[i] = diff_fill;
    n = n_samples[i];
    if (n > 0) {
        diff[i] = (sum_x[i] - sum_y[i]) / n;
    }
    if (n > 2) {
      Sx = sum_x[i];
      Sy = sum_y[i];
      SxSy = Sx * Sy;
      Sxx = sum_x2[i];
      Syy = sum_y2[i];
      Sxy = sum_xy[i];
      Sx2 = Sx * Sx;
      Sy2 = Sy * Sy;
      x_spread = n * Sxx - Sx2;
      y_spread = n * Syy - Sy2;
      if (x_spread > 0.) {
        beta = (n*Sxy - SxSy) / x_spread;
        offset[i] = (Sy - beta * Sx) / n;
        if (y_spread > 0.) {
          correlation[i] = (n * Sxy - SxSy) / 
                            sqrt(x_spread * y_spread);
        }
        stderr2 = (y_spread - (beta*beta) * x_spread) / (n * (n-2));
        slope_err = sqrt(n * stderr2 / x_spread);
        threshold = t_statistic(n-2, 0.95);
        if ( (fabs(beta)/slope_err) > threshold ) {
          slope[i] = beta;
          n_sig++;
        }
      }
    }
  }
  fprintf(stderr, "INFO Number of significant trends (slopes): %d\n", n_sig);
}
double t_statistic(int dof, float p)
{
  static int n[] =       { 
    1,     2,     3,     4,     5,     6,     7,     8,     9,     10,    
   11,    12,    13,    14,    15,    16,    17,    18,    19,     20,    
   21,    22,    23,    24,    25,    26,    27,    28,    29,     30, 
   40,    60,   120,    1000000};
  static double t975[] = { 
   12.706, 4.303, 3.182, 2.776, 2.571, 2.447, 2.365, 2.306, 2.262, 2.228, 
    2.201, 2.179, 2.160, 2.145, 2.131, 2.120, 2.110, 2.101, 2.093, 2.086, 
    2.080, 2.074, 2.069, 2.064, 2.060, 2.056, 2.052, 2.048, 2.045, 2.042, 
    2.021, 2.000, 1.980, 1.960};
  static double t95[] = {   
    6.314, 2.920, 2.353, 2.132, 2.015, 1.943, 1.895, 1.860, 1.833, 1.812, 
    1.796, 1.782, 1.771, 1.761, 1.753, 1.746, 1.740, 1.734, 1.729, 1.725, 
    1.721, 1.717, 1.714, 1.711, 1.708, 1.706, 1.703, 1.701, 1.699, 1.697, 
    1.684, 1.671, 1.658, 1.645}; 

  int i, n_entries;
  if (dof <= 20) return t95[dof-1];

  n_entries = sizeof(n) / sizeof(n[0]);
  for (i = 20; i < n_entries; i++) {
    if (dof < n[i]) {
      return ((t95[i] - t95[i-1]) * (float)(dof - n[i-1]) / (float)(n[i] - n[i-1])  + t95[i-1]);
    }
  }
  return t95[n_entries - 1];
}
