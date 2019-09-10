/*
 * NAME
 *   read_att_into_double - read netcdf numerical attribute into a double
 *
 * SYNOPSIS 
 *   status = read_att_into_double (
 *     int ncid,       # netcdf id for already open file
 *     int varid,      # id for variable that attribute is attached to
 *     char *att_name, # name of attribute to read
 *     double *dblval  # pointer to double for returned value
 *   )
 *
 * DESCRIPTION 
 *   read_att_into_double reads either a short, int, float or double into
 *   a double variable.
 *
 * AUTHOR
 *  Chris Lynnes, NASA/GSFC
 *
 * $Id: read_att.c,v 1.3 2012/06/27 13:09:06 clynnes Exp $
 * -@@@ Giovanni, Version $Name:  $
 */
#include <stdlib.h>
#include <stdio.h>
#include "netcdf.h"

int
read_att_into_double(int ncid, int varid, char *att_name, double *dblval)
{
  nc_type att_type;
  int status;
  float f;
  short s;
  int i;

  /* Query for attribute type */
  status = nc_inq_atttype(ncid, varid, att_name, &att_type);
  /* May not have offset, scale, no worries */
  if (status != NC_NOERR) return 0;

  /* Recast according to type */
  switch (att_type) {
    case NC_SHORT:
      status = nc_get_att_short(ncid, varid, att_name, &s);
      *dblval = (double)s;
      return 1;
    case NC_INT:
      status = nc_get_att_int(ncid, varid, att_name, &i);
      *dblval = (double)i;
      return 1;
    case NC_DOUBLE:
      status = nc_get_att_double(ncid, varid, att_name, dblval);
      return 1;
    case NC_FLOAT:
      status = nc_get_att_float(ncid, varid, att_name, &f);
      *dblval = (double)f;
      return 1;
    default:
      fprintf(stderr, "unsupported type %d for attribute %s\n", att_type, att_name);
      exit(9);
  }
  return 0;
}
