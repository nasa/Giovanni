/*
 * NAME
 *  find_array_bounds - find grid indices corresponding to bounding box
 *
 * SYNOPSIS 
 *  num_points = find_array_bounds (
 *    int verbose,         # 0=ERRORs only; 1=basic DEBUG; 2=detailed DEBUG
 *    int file,            # netcdf file with array
 *    char *var,           # variable name of array
 *    double west,          # western boundary of bounding box
 *    double east,          # eastern boundary of bounding box
 *    double north,         # northern boundary of bounding box
 *    double south,         # southern boundary of bounding box
 *    size_t *start,       # array of start indices to return
 *    size_t *counts,      # array of counts to return
 *    double **lat,        # pointer to array of latitudes within bbox
 *    int *nlat,           # pointer to number of latitudes
 *    double **lon,        # pointer to array of longitudes within bbox
 *    int *nlon            # pointer to number of longitudes
 *  )
 *
 * DESCRIPTION 
 *  For a given netcdf file and variable, we:
 *    open up the file
 *    extract the latitude and longitude dimensions for the variable
 *    find the start grid index and number of points along each dimension
 *    allocate memory and fill the latitude and longitude dimension variable
 *       vectors with the latitudes and longitudes within the bbox
 *  These start and counts arrays will be used to read just the data from
 *  the data files that fall within the bounding box.
 *
 *  Note that the lat/lon arrays are allocated here, but the start and counts 
 *  arrays should already be allocated.
 *
 * AUTHOR
 *  Chris Lynnes, NASA/GSFC
 *
 * $Id: find_bounds.c,v 1.10 2013/11/15 18:43:56 clynnes Exp $
 * -@@@ Giovanni, Version $Name:  $
 */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "netcdf.h"
#include "nccorrelate.h"

static int coord_bounds(int verbose, int ncid, int varid, char *varname, char *units, 
  double lower, double upper, size_t *start, size_t *npts, double **coord);

static int find_coord_varid(int ncid, int varid, char *want_name, char *want_units, int *coord_index);
static char *inq_units(int ncid, int varid);
int in_or_out (double lower, double upper, double *coord, int n_coord, size_t *start, double *keep, int verbose);
int init_start_count(int ncid, int varid, char *name, size_t *start, size_t *count);

int find_array_bounds(int verbose, char *file, char *var, double west, 
  double east, double north, double south, size_t *start, size_t *count, 
  double **lat, int *nlat, double **lon, int *nlon)
{
  int status, ncid, varid, n_coord, coord_id, dim_index, ndims, npts;
  int i, lat_index, lon_index, z_index;
  double *coord;
  double half_width, cell_edge;
  double zval;
  char *zdim = NULL, *zunits = NULL, *varname = NULL;
  char in = 0;
  int n_total = 1;
  if ((status = nc_open(file, NC_NOWRITE, &ncid)) != NC_NOERR) {
    fprintf(stderr, "ERROR failed to open netcdf file %s: %d\n", file, status);
    exit(3);
  }

  /* Parse variable string */
  parse_varstring(var, &varname, &zdim, &zval, &zunits);

  /* Find netCDF index of variable */
  if ((status = nc_inq_varid(ncid, varname, &varid)) != NC_NOERR) {
    fprintf(stderr, "ERROR failed to find variable %s in file %s: %d\n", 
        varname, file, status);
    exit(4);
  }

  /* Initialize all start and count dimensions */
  ndims = init_start_count(ncid, varid, varname, start, count);

  lat_index = coord_bounds(verbose, ncid, varid, NULL, "degrees_north", south, north, start, count, lat);
  lon_index = coord_bounds(verbose, ncid, varid, NULL, "degrees_east", west, east, start, count, lon);
  if (zdim != NULL) {
    z_index = coord_bounds(verbose, ncid, varid, zdim, NULL, zval, zval, start, count, NULL);
  }
  nc_close(ncid);

  /* Compute total number of points */
  for (i = 0, npts = 1; i < ndims; i++) {
    npts *= count[i];
  }
  if (npts == 0) {
    fprintf(stderr, "ERROR no points inside requested bounds\n");
    exit(29);
  }
  *nlat = count[lat_index];
  *nlon = count[lon_index];
  fprintf(stderr, "INFO number of points in array is %d: lat=%d lon=%d\n", npts, *nlat, *nlon);
  return (npts);
}
int coord_bounds(int verbose, int ncid, int varid, char *varname, char *units, 
    double lower, double upper, size_t *start, size_t *count, double **coord_array) {
  int coord_varid, n_coord, coord_index;
  int i;
  double *coord, *keep_coord, *p_coord;
  double half_width, fill;
  int in = 0;

  /* Find which netcdf varid the coordinate in question corresponds to */
  /* Also look for which index it is in the coordinate list */
  coord_varid = find_coord_varid(ncid, varid, varname, units, &coord_index);
  if ((n_coord = read_nc_var(verbose, ncid, coord_varid, NULL, NULL, &coord, &fill)) == 0) {
    fprintf(stderr, "ERROR: failed to read coordinate variable %d\n", coord_varid);
    exit(11);
  }

  /* Allocate a full array's length, even though we will use only some */
  keep_coord = calloc(n_coord, sizeof(double));
  p_coord = keep_coord;
 
  if (verbose > 0) fprintf(stderr, "DEBUG Coord bounds: lower=%f  upper=%f\n", lower, upper);
  count[coord_index] = in_or_out(lower, upper, coord, n_coord, start+coord_index, keep_coord, verbose);
  if (verbose > 0) fprintf(stderr, "DEBUG coord=%d start=%d  counts=%d\n", 
    coord_index, (int)start[coord_index], (int)count[coord_index]);
  if (coord_array != NULL) {
    *coord_array = keep_coord;
  }
  return (coord_index);
}
int 
in_or_out (double lower, double upper, double *coord, int n_coord, size_t *start, double *keep, int verbose)
{
  int i, in, count;
  double *p_coord = keep;

  /* First see if there is any intersection at all */
  double direction = coord[n_coord-1] - coord[0];
  if (direction > 0. && (upper < coord[0] || lower > coord[n_coord-1])) {
    fprintf(stderr, "ERROR Found no points between %lf and %lf\n", lower, upper);
    fprintf(stderr, "DEBUG Data coordinates increase from %lf to %lf\n", coord[0], coord[n_coord-1]);
    return 0;
  }
  if (direction < 0. && (upper < coord[n_coord-1] || lower > coord[0])) {
    fprintf(stderr, "ERROR Found no points between %lf and %lf\n", lower, upper);
    fprintf(stderr, "DEBUG Data coordinates decrease %lf to %lf\n", coord[0], coord[n_coord-1]);
    return 0;
  }
  /* Looking at each coordinate to see if it falls between lower and upper 
   * This should work with either increasing or decreasing coordinates,
   * but they must be monotonic.
   */
  for (i = 0, in = 0, count = 0; i < n_coord; i++) {
    if (!in && coord[i] >= lower && coord[i] <= upper) {
      *start = i;
      in = 1;
    }
    else if (in && (coord[i] < lower || coord[i] > upper)) { /* off the end */
      count = i - *start;
      break;
    }
    /* If it's inside the range, it's a keeper */
    if (in) {
      *p_coord++ = coord[i];
    }
    if (verbose > 2) fprintf(stderr, "DEBUG coord=%f in=%d\n", coord[i], in);
  }
  /* Do not have any counted yet */
  if (count == 0) {
    if (in) return(i - *start);
    double middle = 0.5 * (upper + lower);
    if (verbose > 2) fprintf(stderr, "DEBUG center point of small box: %lf between %lf and %lf\n", middle, lower, upper);
    int closest_index = 0;
    double distance;
    double closest_distance = fabs(middle - coord[0]);
    for (i = 1; i < n_coord; i++) {
       if (verbose > 2) fprintf(stderr, "DEBUG coord=%f distance=%f closest distance=%f\n", coord[i], distance, closest_distance);
       distance = fabs(middle - coord[i]);
       if (distance < closest_distance) {
          closest_distance = distance;
          closest_index = i;
       }
    }
    count = 1;
    *start = closest_index;
    *p_coord = coord[closest_index];
  }
  return count;
}
/* Can find coordinate either by its name (varname) or characteristic units
 * like degrees_east 
 */
int find_coord_varid(int ncid, int varid, char *want_name, char *want_units, int *coord_index) {
  int status, ndims, dim_varid;
  int i;
  int dimids[NC_MAX_VAR_DIMS];
  char dimname[NC_MAX_NAME+1];
  char *got_units;

  /* Get number of dimensions */
  if ((status = nc_inq_varndims(ncid, varid, &ndims)) != NC_NOERR) {
    fprintf(stderr, "ERROR finding ndims for varid %d: %d", varid, status);
    exit(-status);
  }
  /* Get list of dimids used by this variable */
  if ((status = nc_inq_vardimid(ncid, varid, dimids)) != NC_NOERR) {
    fprintf(stderr, "ERROR finding dimids for varid %d: %d", varid, status);
    exit(-status);
  }

  /* Loop through dimensions, looking for our target one */
  for (i = 0; i < ndims; i++) {
    /* Get dimension name */
    if ((status = nc_inq_dimname(ncid, dimids[i], dimname)) != NC_NOERR) {
      fprintf(stderr, "ERROR finding name for dimid %d: %d", dimids[i], status);
      exit(-status);
    }
    else {
      fprintf(stderr, "DEBUG inspecting dimension %s\n", dimname);
    }

    /* Get dim_varid */
    if ((status = nc_inq_varid(ncid, dimname, &dim_varid)) != NC_NOERR) {
      fprintf(stderr, "ERROR finding varid for dimension %s: %d", dimname, status);
      exit(-status);
    }

    /* If we have a want_name, just compare with that */
    if (want_name != NULL && strcmp(want_name, dimname) == 0) {
      *coord_index = i;
      return dim_varid;
    }
    /* Otherwise, look for characteristic units, like degrees_north */
    else if (want_units != NULL) {
      got_units = inq_units(ncid, dim_varid);
      if (got_units && strcmp(got_units, want_units)==0) {
        *coord_index = i;
        free(got_units);
        return dim_varid;
      }
    }
  }

  /* Darn, didn't get one:  report error */
  if (want_name) fprintf(stderr, "ERROR Could not find dimension %s\n", want_name);
  else fprintf(stderr, "ERROR Could not find units attribute matching %s\n", want_units);
  exit(20);
}

char *inq_units(int ncid, int varid) {
  size_t attlen;
  int status;
  char *buf;
  status = nc_inq_attlen(ncid, varid, "units", &attlen);
  if (status != NC_NOERR) return NULL;
  buf = malloc(attlen + 1);
  status = nc_get_att_text(ncid, varid, "units", buf);
  buf[attlen]='\0';
  if (status != NC_NOERR) {
    fprintf(stderr, "ERROR could not retrieve units attribute from varid %d: %d",
      varid, status);
    exit(-status);
  }
  return buf;
}
int init_start_count(int ncid, int varid, char *name, size_t *start, size_t *count)
{
  int i, n, status, ndims, dims[NC_MAX_VAR_DIMS];
  if ((status = nc_inq_var(ncid, varid, NULL, NULL, &ndims, dims, NULL)) != NC_NOERR) {
    fprintf(stderr, "ERROR retrieving info about variable %s: %d %s\n",
      name, status, nc_strerror(status));
    exit(-status);
  }
  for (i = 0, n = 1; i < ndims; i++) {
    start[i] = 0;
    if ((status = nc_inq_dimlen(ncid, dims[i], count+i)) != NC_NOERR) {
      fprintf(stderr, "ERROR retrieving info about dimension %d: %d %s\n",
        dims[i], status, nc_strerror(status));
      exit(-status);
    }
    n *= count[i];
  }
  return ndims;
}
