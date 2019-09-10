#include <sys/types.h>

void accumulate(int verbose, int n, char **files, long epoch, char **vars, size_t **start,
  size_t **npts, double *sum_x2, double *sum_y2, double *sum_xy,
  double *sum_x, double *sum_y, int *nsamples);

extern void array_regression (int n, double *sum_x2, double *sum_y2, 
  double *sum_xy, double *sum_x, double *sum_y, int *n_samples, 
  double *correlation, double correlation_fill, double *slope, double slope_fill,
  double *offset, double offset_fill, double *diff, double diff_fill);

extern char *cdl2nc(char *basename, char *rename_file);

extern int check(double val, double correct, double tolerance, char *name);

extern int find_array_bounds(int verbose, char *file, char *var,
  double west, double east, double north, double south,
  size_t *start, size_t *npts, double **lat, int *nlat, double **lon, int *nlon);

extern int parse_varstring(char *varstring, char **varname, char **zdim, double *zval, char **zunits);

extern int read_att_into_double(int ncid, int varid, char *att_name, double *dblval);

extern int read_nc_var(int verbose, int ncid, int varid, 
  size_t *start, size_t *npts, double **d, double *fill);

extern double t_statistic(int dof, float p);

extern int write_netcdf_output(int verbose, char *outfile,
  int nx, int ny, int *n_samples, double *correlation, double correlation_fill,
  double *slope, double slope_fill, double *offset, double offset_fill,
  double *diff, double diff_fill,
  double *sum_x, double *sum_y, double *sum_xy, double *sum_x2, double *sum_y2,
  double *lat, double *lon);
