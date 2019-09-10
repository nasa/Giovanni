/*
 * NAME
 *  check - compare two doubles within a given threshold
 *
 * SYNOPSIS 
 *  match = check(
 *   double value,         # Value to compare
 *   double correct_value, # What the value should be
 *   double tolerance,     # Tolerance for comparison
 *   char *name            # Name of value (for error report)
 *  )
 *
 * DESCRIPTION 
 *  check compares two doubles within a given tolerance.
 *  If the values are different, it reports an error to stderr and returns 1.
 *  If the values are the same within tolerance, it simply returns 0.
 *
 * AUTHOR
 *  Chris Lynnes, NASA/GSFC
 *
 * $Id: check.c,v 1.4 2012/06/27 13:09:06 clynnes Exp $
 * -@@@ Giovanni, Version $Name:  $
 */
#include <stdio.h>
#define ABS(X)  (((X)<0.) ? -(X) : (X))

int check(double val, double correct, double tolerance, char *name)
{
  if (ABS(val - correct) > tolerance) {
    fprintf(stderr, "ERROR on %s: Actual=%lf  Correct=%lf (Tolerance=%lf)\n",
      name, val, correct, tolerance);
    return 1;
  }
  return 0;
}
