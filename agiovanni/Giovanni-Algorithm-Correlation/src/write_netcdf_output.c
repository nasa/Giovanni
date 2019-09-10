/*
 * NAME
 *   write_netcdf_output - write data to a netcdf file
 *
 * SYNOPSIS 
 *   int write_netcdf_output(
 *     int verbose,            # Verbosity level, 0-4
 *     char *outfile,          # Output file pathname
 *     int nlat,               # Number of latitudes
 *     int nlon,               # Number of longitudes
 *     int *n_samples,         # Number of samples for each grid cell
 *     double *correlation,    # R values for each grid cell
 *     double correlation_fill,# Fill value for correlation
 *     double *slope,          # Slope values for each grid cell
 *     double slope_fill,      # Fill value for slope
 *     double *offset,         # Offset values for each grid cell
 *     double offset_fill,     # Fill value for offset
 *     double *diff,           # Averaged difference for each grid cell
 *     double diff_fill,       # Fill value for the difference
 *     double *sum_x,          # Sum of x
 *     double *sum_y,          # Sum of y
 *     double *sum_xy,         # Sum of x * y
 *     double *sum_x2,         # Sum of x**2
 *     double *sum_y2,         # Sum of y**2
 *     double *lat,            # Latitude dimension values
 *     double *lon             # Longitude dimension values
 *   )
 *
 * DESCRIPTION 
 *   write_netcdf_output writes a CF-1 compliant (mostly) file containing
 *   all of the grids passed in the arguments.
 *   It takes an output filename, creates the file, writes the file, then 
 *   closes the file.
 *   If it returns successfully, it returns 0.
 *
 * AUTHOR
 *  Chris Lynnes, NASA/GSFC
 *
 * $Id: write_netcdf_output.c,v 1.12 2013/04/30 14:47:07 jpan Exp $
 * -@@@ Giovanni, Version $Name:  $
 */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "netcdf.h"

static void add_text_attribute (int ncid, int varid, char *varname, 
  char *name, char *val);

static void prep_double_var(int verbose, char *varname, int *varid, int ncid, 
  int *dims, int n_dim, double *fill_value);

static int prep_n_samples(int ncid, int *dims, int n_dim);

static int setup_dim(int ncid, int n, const char *name, char *standard_name,
  char *units, nc_type xtype, int *p_varid);

static int setup_spatial_dim(int ncid, int n, const char *name, int *varid);

static int *write_map_netcdf (int verbose, int ncid, int n_vars, 
  char **varnames, int *n_samples, double **data, double *fill_values, 
  int nlat, int nlon, double *lat, double *lon);

int 
write_netcdf_output(int verbose, char *outfile, int nlat, int nlon,
  int *n_samples, double *correlation, double correlation_fill, 
  double *slope, double slope_fill, double *offset, double offset_fill,
  double *diff, double diff_fill,
  double *sum_x, double *sum_y, double *sum_xy, double *sum_x2, double *sum_y2,
  double *lat, double *lon)
{
  int ncid, status, n_datasets, *varids;
  char *convention = "CF-1.4";
  char *varnames[] = {"correlation", "slope", "offset", "time_matched_difference", "sum_x", "sum_y", 
    "sum_xy", "sum_x2", "sum_y2"};
  double *data[] = {correlation, slope, offset, diff, sum_x, sum_y, sum_xy, sum_x2, sum_y2};
  double fill_values[] = {correlation_fill, slope_fill, offset_fill, diff_fill, diff_fill, diff_fill, 0., 0., 0.};
  
  if (verbose > 2) {
    fprintf(stderr, "DEBUG writing output to %s\n", outfile);
    fprintf(stderr, "DEBUG array is %d (lat) x %d (lon)\n", nlat, nlon);
  }

  /* Open file for writing */
  if ((status = nc_create(outfile, NC_CLOBBER, &ncid)) != NC_NOERR) {
    fprintf(stderr, "ERROR failed to nc_create %s: %s\n", 
      outfile, nc_strerror(status));
    exit(-status);
  }
  if (verbose > 1) {
    fprintf(stderr, "INFO opened file %s for writing\n", outfile);
  }
  /* Add global Conventions attribute */
  if ((status = nc_put_att_text(ncid, NC_GLOBAL, "Conventions", strlen(convention), convention)) != NC_NOERR) {
      fprintf(stderr, "ERROR adding global Conventions attribute: %d %s\n", status, nc_strerror(status));
      exit(-status);
  }
  if (verbose > 2) fprintf(stderr, "DEBUG Added Conventions attribute\n");

  /* If sum_x has a value, we will write out all the sums as well */
  /* sum_x and sum_y are always written out for time averaged means */
  n_datasets = (sum_xy == (double *)NULL) ? 6 : 9;
  varids = write_map_netcdf(verbose, ncid, n_datasets, varnames,
     n_samples, data, fill_values, nlat, nlon, lat, lon);

  /* Close file */
  if ((status = nc_close(ncid)) != NC_NOERR) {
    fprintf(stderr, "ERROR closing file: %d %s\n", status, nc_strerror(status));
    exit(-status);
  }
  if (verbose) fprintf(stderr, "INFO Wrote file %s\n", outfile);
  free(varids);
  return 0;
}
int *
write_map_netcdf (int verbose, int ncid, int n_vars, char **varnames,
   int *n_samples, double **data, double *fill_values,
   int nlat, int nlon, double *lat, double *lon)
{
    int latvar, lonvar;
    int *varids;
    int dims[2];
    int i;
    int status;

    /* Allocate varids for all the varnames, + n_samples */
    varids = malloc((n_vars+1) * sizeof(int));

    /* set up dimensions */
    dims[1] = setup_spatial_dim(ncid, nlon, "longitude", &lonvar);
    dims[0] = setup_spatial_dim(ncid, nlat, "latitude", &latvar);

    /* Set up dimensions and attributes for input files */
    for (i = 0; i < n_vars; i++) {
        prep_double_var(verbose, varnames[i], varids+i, ncid, dims, 2, fill_values+i);
    }

    /* Add varid for n_samples at the end */
    varids[n_vars] = prep_n_samples(ncid, dims, 2);
    if (verbose > 2) fprintf(stderr, "DEBUG Done with variable prepation\n");


    /* Add text attributes to identify plottable variables */
    add_text_attribute(ncid, varids[0], varnames[0], "quantity_type", "correlation");
    add_text_attribute(ncid, varids[3], varnames[3], "quantity_type", "difference");
    add_text_attribute(ncid, varids[n_vars], varnames[n_vars], "quantity_type", "count");
    add_text_attribute(ncid, varids[n_vars], varnames[n_vars], "units", "count");

    /* Finish defining variables */
    if ((status = nc_enddef(ncid) ) != NC_NOERR) {
        fprintf(stderr, "ERROR in nc_enddef: %d %s\n", status, nc_strerror(status));
        exit(-status);
    }
    if (verbose > 3) fprintf(stderr, "DEBUG Completed nc_enddef\n");

    /* Write latitudes to file */
    if ((status = nc_put_var_double(ncid, latvar, lat)) != NC_NOERR) {
        fprintf(stderr, "ERROR putting var to lat array: %d %s\n", status, nc_strerror(status));
        exit(-status);
    }
    /* Write longitudes to file */
    if ((status = nc_put_var_double(ncid, lonvar, lon)) != NC_NOERR) {
        fprintf(stderr, "ERROR putting var to lon array: %d %s\n", status, nc_strerror(status));
        exit(-status);
    }
    if (verbose > 2) {
      fprintf(stderr, "DEBUG Done writing latitude/longitude variables\n");
    }

    /* Write n_samples to file */
    if ((status = nc_put_var_int(ncid, varids[n_vars], n_samples)) != NC_NOERR) {
        fprintf(stderr, "ERROR putting var to n_samples array: %d %s\n", status, nc_strerror(status));
        exit(-status);
    }

    /* Write data variables */
    for (i = 0; i < n_vars; i++) {
        if (verbose > 2) {
          fprintf(stderr, "DEBUG Writing out dataset %s...\n", varnames[i]);
        }
        status = nc_put_var_double(ncid, varids[i], (double *)data[i]);
        if (status != NC_NOERR) {
            fprintf(stderr, "ERROR defining variable: %d %s\n", status, nc_strerror(status));
            exit(-status);
        }
    }

    return varids;
}

/* add_text_attribute */
void
add_text_attribute (int ncid, int varid, char *varname, char *name, char *val)
{
  int status;
  if ((status = nc_put_att_text(ncid, varid, name, strlen(val), val)) != NC_NOERR) {
    fprintf(stderr, "ERROR adding attribute %s to variable %s: %d %s\n", 
      name, varname, status, nc_strerror(status));
    exit(-status);
  }
}

/* prep_n_samples is much simpler than prep_double_var */
int 
prep_n_samples(int ncid, int *dims, int n_dim)
{
  int status, varid;
  char *long_name = "Number of samples";
  if ((status = nc_def_var(ncid, "n_samples", NC_INT, n_dim, dims, &varid)) != NC_NOERR) {
    fprintf(stderr, "ERROR defining n_samples: %d %s\n", status, nc_strerror(status));
    exit(12);
  }
  if ((status = nc_put_att_text(ncid, varid, "long_name", strlen(long_name), long_name)) != NC_NOERR) {
    fprintf(stderr, "ERROR adding attribute long_name to n_samples: %d %s\n", status, nc_strerror(status));
    exit(12);
  }
  return varid;
}
void
prep_double_var(int verbose, char *varname, int *varid, int ncid, 
  int *dims, int n_dim, double *fill_value)
{
  int status;
  if (verbose > 2) {
    fprintf(stderr, "DEBUG Setting up variable %s\n", varname);
    fprintf(stderr, "DEBUG fill_value = %lf\n", *fill_value);
  }
  /* Step 1:  Define the variable */
  if ((status = nc_def_var(ncid, varname, NC_DOUBLE, n_dim, dims, varid)) != NC_NOERR) {
    fprintf(stderr, "ERROR defining variable: %d %s\n", status, nc_strerror(status));
    exit(12);
  }
  if (verbose > 2) fprintf(stderr, "DEBUG Defined variable %s\n", varname);

  /* Step 2: Add long_name */
  if ((status = nc_put_att_text(ncid, *varid, "long_name", strlen(varname), varname)) != NC_NOERR) {
    fprintf(stderr, "ERROR adding attribute long_name: %d %s\n", status, nc_strerror(status));
    exit(12);
  }
  if (verbose > 2) {
    fprintf(stderr, "DEBUG Added long_name to variable %s\n", varname);
  }

  /* Step 3: Add _FillValue attribute */
  if (fill_value != (double *)NULL) {
    if ((status = nc_put_att_double(ncid, *varid, "_FillValue", NC_DOUBLE, 1, fill_value)) != NC_NOERR) {
      fprintf(stderr, "ERROR adding attribute _FillValue: %d %s\n", status, nc_strerror(status));
      exit(12);
    }
  }

  if (verbose > 2) {
    fprintf(stderr, "DEBUG Done setting up variable %s\n", varname);
  }
  return;
}

int 
setup_dim(int ncid, int n, const char *name, char *standard_name,
  char *units, nc_type xtype, int *p_varid)
{
  int status, dim[1], varid;
  /* Step 0: Sanity check:  is dimension at least length 1? */
  if (n <= 0) {
    fprintf(stderr, "ERROR setting up spatial dimension: n<= 0\n");
    exit(11);
  }

  /* Step 1: Define dimension */
  if ((status = nc_def_dim(ncid, name, n, dim)) != NC_NOERR) {
    fprintf(stderr, "ERROR defining spatial dimension: %d %s\n", status, nc_strerror(status));
    exit(11);
  }

  /* Step 2: Define corresponding variable */
  if ((status = nc_def_var(ncid, name, xtype, 1, dim, &varid)) != NC_NOERR) {
    fprintf(stderr, "ERROR defining variable %s: %d %s\n", name, status, nc_strerror(status));
    exit(12);
  }

  /* Step 3: Add long_name attribute */
  if ((status = nc_put_att_text(ncid, varid, "long_name", strlen(name), name)) != NC_NOERR) {
    fprintf(stderr, "ERROR adding attribute long_name: %d %s\n", status, nc_strerror(status));
    exit(12);
  }

  /* Step 4: Add standard_name */
  /* TO DO: What if not set? */
  if ((status = nc_put_att_text(ncid, varid, "standard_name", strlen(standard_name), standard_name)) != NC_NOERR) {
        fprintf(stderr, "ERROR adding attribute standard_name: %d %s\n", status, nc_strerror(status));
        exit(12);
    }

    /* Step 5: Add units attribute */
    if (units != NULL) {
      if ((status = nc_put_att_text(ncid, varid, "units", strlen(units), units)) != NC_NOERR) {
        fprintf(stderr, "ERROR adding attribute units to %s: %d %s\n", units, status, nc_strerror(status));
        exit(12);
      }
    }
    *p_varid = varid;
    return dim[0];
}

/* Convenience routine to set units and standard name for spatial dimensions */
int
setup_spatial_dim(int ncid, int n, const char *name, int *p_varid)
{
  char units[MAX_NC_NAME], standard_name[MAX_NC_NAME];
  if ((strcasecmp(name, "latitude")==0)) {
    strcpy(units, "degrees_north");
    strcpy(standard_name, "latitude");
  }
  else {
    strcpy(units, "degrees_east");
    strcpy(standard_name, "longitude");
  }
  return setup_dim(ncid, n, name, standard_name, units, NC_DOUBLE, p_varid);
}
