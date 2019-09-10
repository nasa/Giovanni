/*
 * NAME
 *   read_nc_var - read a variable and its fill value from a netCDF file
 *
 * SYNOPSIS 
 *   nread = read_nc_var (
 *     int verbose,     # verbose level
 *     int ncid,        # id of already open netcdf file
 *     int varid,       # id of variable to be opened
 *     size_t *start,   # array of start indices for each dimension
 *     size_t *count,   # array of number of points to read for each dimension
 *     double **d,      # address to put the pointer for the allocated array
 *     double *fill     # address to put the fill value
 *   )
 *
 * DESCRIPTION 
 *   read_nc_var reads a variable array and converts (if necessary) to an
 *   array of doubles.  It takes a start[] and count[] array (length is
 *   equal to the number of dimensions) to subset the array.
 *   The variable may be short, int, float or double.  All will be converted to
 *   double and unpacked by applying scale_factor and add_offset attribute
 *   values.
 *
 *   The returned value is the number of points returned in the array.
 *
 *   Note that the double array is allocated in this routine. 
 * TO DO
 *   Use the count[] array to figure how many points for allocation
 *
 * AUTHOR
 *  Chris Lynnes, NASA/GSFC
 *
 * $Id: read_nc_var.c,v 1.6 2012/06/29 21:47:19 clynnes Exp $
 * -@@@ Giovanni, Version $Name:  $
 */
#include <stdlib.h>
#include <stdio.h>
#include "netcdf.h"

int
read_nc_var(int verbose, int ncid, int varid, size_t *start, size_t *count, double **data, double *fill)
{
    int i, n;
    int *ival;
    double *dval;
    float *fval;
    short *sval;
    size_t dimlen;
    double add_offset = 0.;
    double scale_factor = 1.;
    char name[NC_MAX_NAME];
    int dimids[NC_MAX_DIMS];
    int status, vartype, ndims, natts, n_red;

    /* Read dimensions to compute the number of points */
    status = nc_inq_var(ncid, varid, name, &vartype, &ndims, dimids, &natts);

    /* Read scale_factor, add_offset and _FillValue */
    read_att_into_double(ncid, varid, "scale_factor", &scale_factor);
    read_att_into_double(ncid, varid, "add_offset", &add_offset);
    read_att_into_double(ncid, varid, "_FillValue", fill);

    /* Unpack fill value */
    *fill = *fill * scale_factor + add_offset;

    /* Compute total number of elements */
    for (i = 0, n = 1; i < ndims; i++) {
      if (count == NULL) {
        status = nc_inq_dimlen(ncid, dimids[i], &dimlen);
        if (status != NC_NOERR) exit(12);
        n *= dimlen;
      }
      else {
        n *= count[i];
      }
    }
    if (verbose > 1) {
      fprintf(stderr, "DEBUG Scale = %lf\n", scale_factor);
      fprintf(stderr, "DEBUG Offset = %lf\n", add_offset);
      fprintf(stderr, "DEBUG N = %d\n", n);
    }

    /* Allocate the array of doubles */
    dval = malloc(n * sizeof(double));

    /* Read the whole array */
    switch(vartype) {
      case NC_SHORT:
        sval = malloc(n * sizeof(short));
        status = (start == NULL) ? nc_get_var_short(ncid, varid, sval)
                                 : nc_get_vara_short(ncid, varid, start, count, sval);
        if (status != NC_NOERR) {
          fprintf(stderr, "ERROR reading variable %s: %d (%s)\n", 
            name, status, nc_strerror(status));
          exit(-status);
        }
        /* Unpack into doubles */
        for (i = 0; i < n; i++) {
          dval[i] = sval[i] * scale_factor + add_offset;
        }
        free(sval);
        break;
      case NC_INT:
        ival = malloc(n * sizeof(int));
        status = (start == NULL) ? nc_get_var_int(ncid, varid, ival)
                                 : nc_get_vara_int(ncid, varid, start, count, ival);
        if (status != NC_NOERR) {
          fprintf(stderr, "ERROR reading variable %s: %d (%s)\n", 
            name, status, nc_strerror(status));
          exit(-status);
        }
        /* Unpack into doubles */
        for (i = 0; i < n; i++) {
          dval[i] = ival[i] * scale_factor + add_offset;
        }
        free(ival);
        break;
      case NC_FLOAT:
        fval = malloc(n * sizeof(float));
        status = (start == NULL) ? nc_get_var_float(ncid, varid, fval)
                                 : nc_get_vara_float(ncid, varid, start, count, fval);
        if (status != NC_NOERR) {
          fprintf(stderr, "ERROR reading variable %s: %d (%s)\n", 
            varid, status, nc_strerror(status));
          exit(-status);
        }
        for (i = 0; i < n; i++) {
          dval[i] = fval[i] * scale_factor + add_offset;
        }
        free(fval);
        break;
      case NC_DOUBLE:
        status = (start == NULL) ? nc_get_var_double(ncid, varid, dval)
                                 : nc_get_vara_double(ncid, varid, start, count, dval);
        if (status != NC_NOERR) {
          fprintf(stderr, "ERROR reading varid %s: %d (%s)\n", 
            name, status, nc_strerror(status));
          exit(-status);
        }
        /* Unpack array */
        for (i = 0; i < n; i++) {
          dval[i] = dval[i] * scale_factor + add_offset;
        }
        break;
      default:
        fprintf(stderr, "unsupported type %d\n", vartype);
        exit(9);
    }
    *data = dval;
    if (verbose > 1) fprintf(stderr, "DEBUG number of points is %d\n", n);
    return n;
}
