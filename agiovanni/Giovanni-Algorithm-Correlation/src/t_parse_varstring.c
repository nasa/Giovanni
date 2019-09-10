#include <stdlib.h>
#include <stdio.h>
#include "nccorrelate.h"

int main(int argc, char **argv) {
  char *varname, *zdim, *zunits;
  double zval;
  int rc;

  rc = parse_varstring("foo", &varname, &zdim, &zval, &zunits);
  if (rc != 0) {
    fprintf(stderr, "D'oh:  should have gotten 0, but got %d\n", rc);
    exit(1);
  }
  rc = parse_varstring("foo_bar,Pressure_A=650.2hPa", &varname, &zdim, &zval, &zunits);
  if (strcmp(varname, "foo_bar") != 0) {
    fprintf(stderr, "Did not get the right variable name (%s != foo_bar)\n", varname);
    exit(2);
  }
  if (strcmp(zdim, "Pressure_A") != 0) {
    fprintf(stderr, "Did not get the right dimension name (%s != Pressure_A)\n", zdim);
    exit(3);
  }
  if (strcmp(zunits, "hPa") != 0) {
    fprintf(stderr, "Did not get the right units (%s != hPa)\n", zdim);
    exit(4);
  }
  if (zval != 650.2) {
    fprintf(stderr, "Did not get the right zval (%f != 650.2)\n", zval);
    exit(5);
  }
  exit(0);
}

  
