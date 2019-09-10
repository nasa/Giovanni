/*
=head1 NAME

nccorrelate - cross-correlate a pair of gridded data series

=head1 SYNOPSIS

nccorrelate 
B<-v> I<verbosity>
B<-i> I<control_file> 
B<-o> I<netcdf_file> 
B<-x> I<variable>
B<-y> I<variable>
[B<-w> I<west_edge>]  
[B<-e> I<east_edge>]
[B<-n> I<north_edge>]
[B<-s> I<south_edge>]
[B<-v> I<verbose_level>]

=head1 DESCRIPTION

nccorrelate produces a cross-correlation at each grid point between
two arrays.

=head1 ARGUMENTS

=over 4

=item B<-v> I<verbosity level> 

Can be from 0 (least verbose) to 3 
(most verbose, with sums written to output file).

=item B<-i> I<input_file> 

Filename for the input file.  This file has pairs of files, one pair per line.
Each pair is a time-matched pair of files for two different variables.

=item B<-o> I<netcdf_file> 

Output netcdf filename.

=item B<-x> I<variable> 

First variable to correlation (aka 'X'). 
For slices from vertical dimensions, this may be of the form:
I<var,dimName=zValue>, where I<dimName> is the name of the
variable's Z dimension (e.g., TempPrsLvls_A) and I<zValue>
is the dimension value for the desired slice, e.g., 
I<-x> B<TempPrsLvls_A=500hPa>.

=item B<-y> I<variable> 

Second variable to correlation (aka 'Y').

=item [B<-w> I<west_edge>]  

Longitude of western edge. Default = -180.

=item [B<-e> I<east_edge>]

Longitude of eastern edge. Default = 180.

=item [B<-n> I<north_edge>]

Latitude of northern edge.  Default = 90.

=item [B<-s> I<south_edge>]

Latitude of southern edge.  Default = -90.

=item [B<-v> I<verbose_level>]

Verbose level controls the amount of DEBUG messages that are written.
0 suppresses all DEBUG statements.  At the high end, a verbose 
level of 3 also results in writing the accumulation arrays to 
the netcdf file.

=back

=head1 EXAMPLE

nccorrelate -o xcorr.nc -i input_files.txt -v 3 -w 8 -e 22 -n 40 -s 26 -x Optical_Depth_Land_And_Ocean_Mean -y Optical_Depth_Land_And_Ocean_Mean

=head1 AUTHOR

Chris Lynnes, Chris.Lynnes@nasa.gov

=cut
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "netcdf.h"
#include "nccorrelate.h"

/* Defines */
#define MAXPATHLEN 256
#define MAXLINELEN (MAXPATHLEN*2+2)
#define MAXDIM 5

/* Static vars for parsing command line */
static int nx = 0;
static int ny = 0;
static double north = 90.;
static double south = -90.;
static double east = 180.;
static double west = -180.;
static char *infile = NULL;
static char *outfile = NULL;
static char *var1 = NULL;
static char *var2 = NULL;
static long epoch = -1;
static int s_verbose = 0;

void allocate_grids(int n, double **sum_x2, double **sum_y2, double **sum_xy, 
  double **sum_x, double **sum_y, int **nsamples, 
  double **correlation, double **slope, double **offset, double **diff);

void parse_args(int argc, char **argv, char **outfile, char **infile,
  char **var1, char **var2,
  double *n, double *s, double *e, double *w, 
  long *epoch, int *verbose);

void usage();

void usage_error(char *s);

int
main(int argc, char **argv)
{
    int i, j;
    int status;
    size_t *starts[2], *counts[2];
    int n1, n2, npts, n_files;
    int n_fill = 0;
    double *sum_x2, *sum_y2, *sum_xy, *sum_x, *sum_y;
    double *correlation = NULL, *slope = NULL, *offset = NULL, *diff = NULL;
    double *lat, *lon;
    int nlat, nlon;
    int *n_samples = NULL;
    char line[MAXLINELEN+1];
    char *files[2];
    char *vars[2];
    char *basename;
    FILE *fp;
    double *sums[5];

    sum_x2 = (double *)NULL;

    /* Parse command line arguments */
    parse_args(argc, argv, &outfile, &infile, vars+0, vars+1, 
      &north, &south, &east, &west, 
      &epoch, &s_verbose);
    fprintf(stderr, "DEBUG verbose level = %d\n", s_verbose);

    /* Open input file */
    if ((fp = fopen(infile, "r")) == (FILE *)NULL) {
      fprintf(stderr, "ERROR failed to open file %s\n", infile);
      exit(2);
    }

    /* Going to use these all program, no need to free until end */
    files[0] = malloc(MAXPATHLEN);

    /* If epoch is set, we regress the variable vs. time, not another variable */
    if (epoch < 0) files[1] = malloc(MAXPATHLEN);
    n_files = (epoch < 0) ? 2 : 1;

    /* allocate start and counts arrays (used in nc_get_vars()) for each file */
    for (i = 0; i < n_files; i++) {
      starts[i] = malloc(MAXDIM * sizeof(size_t));
      for (j = 0; j < MAXDIM; j++) {
        starts[i][j] = 0;
      }
      counts[i] = malloc(MAXDIM * sizeof(size_t));
    }

    /* Loop through files */
    while (fgets(line, MAXLINELEN, fp) != (char *)NULL) {
      if (epoch < 0) sscanf(line, "%s %s\n", files[0], files[1]);
      else sscanf(line, "%s\n", files[0]);

      /* Output lineage */
      fprintf(stderr, "LINEAGE_INPUT type=\"FILE\" label=\"Input file A\" value=\"%s\"\n", files[0]);
      if (epoch < 0) fprintf(stderr, "LINEAGE_INPUT type=\"FILE\" label=\"Input file B\" value=\"%s\"\n", files[1]);

      /* First pair of files, find array bounds and allocate */
      if (sum_x2 == (double *)NULL) {
        if (s_verbose > 2) fprintf(stderr, "DEBUG finding array bounds\n");
        n1 = find_array_bounds(s_verbose, files[0], vars[0], west, east, north, south, starts[0], counts[0], &lat, &nlat, &lon, &nlon);
        if (epoch < 0) {
          n2 = find_array_bounds(s_verbose, files[1], vars[1], west, east, north, south, starts[1], counts[1], &lat, &nlat, &lon, &nlon);
          if (n1 != n2) {
            fprintf(stderr, "ERROR mismatched arrays: %d vs. %d points\n", n1, n2);
            exit(21);
          }
        }
        allocate_grids(n1, &sum_x2, &sum_y2, &sum_xy, &sum_x, &sum_y, 
            &n_samples, &correlation, &slope, &offset, &diff);
      }
      accumulate(s_verbose, n1, files, epoch, vars, starts, counts, sum_x2, sum_y2, sum_xy, sum_x, sum_y, n_samples);
    }
    if (ferror(fp)) {
      fprintf(stderr, "ERROR %d reading file %s\n", ferror(fp), infile);
      exit(1);
    }
    fclose(fp);
    if (sum_x2 == (double *)NULL) {
      fprintf(stderr, "ERROR no data read\n");
      exit(3);
    }

    /* MAIN COMPUTATION FUNCTION: compute regression, R, matched sum_x, sum_y... */
    array_regression(n1, sum_x2, sum_y2, sum_xy, sum_x, sum_y, n_samples, 
      correlation, NC_FILL_DOUBLE, slope, NC_FILL_DOUBLE, offset, NC_FILL_DOUBLE, diff, NC_FILL_DOUBLE);

    /* For low verbosity (=debug) levels, suppress writing the accumulators 
       by replacing their pointers with with NULLs, except sum_x and sum_y
       which will be used to derive time averaged fields.
    */
    if (s_verbose < 3) {
      for (i = 2; i < 5; i++) sums[i] = NULL;
      sums[0] = sum_x;
      sums[1] = sum_y;
    }
    else {
      sums[0] = sum_x;
      sums[1] = sum_y;
      sums[2] = sum_xy;
      sums[3] = sum_x2;
      sums[4] = sum_y2;
      if (s_verbose > 0) fprintf(stderr, "DEBUG saving sums to output file\n");
    }

    if ( (status = write_netcdf_output(s_verbose, outfile, nlat, nlon,
        n_samples, correlation, NC_FILL_DOUBLE, slope, NC_FILL_DOUBLE, 
        offset, NC_FILL_DOUBLE, diff, NC_FILL_DOUBLE, sums[0], sums[1], sums[2], sums[3], sums[4],
        lat, lon) == NC_NOERR)) {
      fprintf(stderr, "INFO Output file is %s\n", outfile);
    }
    else {
      exit(-status);
    }

    /* Free just as good practice */
    free(sum_x);
    free(sum_y);
    free(sum_x2);
    free(sum_y2);
    free(sum_xy);
    free(n_samples);
    free(correlation);
    free(slope);
    free(offset);
    free(diff);
    /* For pairs of files */
    for (i = 0; i < n_files; i++) {
      free(files[i]);
      free(starts[i]);
      free(counts[i]);
    }
    exit(0);
}
void allocate_grids(int n, double **sum_x2, double **sum_y2, double **sum_xy, 
  double **sum_x, double **sum_y, int **nsamples, double **correlation, double **slope, double **offset, double **diff)
{
  double **dbl_ptrs[] = {sum_x2, sum_y2, sum_xy, sum_x, sum_y, 
    correlation, slope, offset, diff};
  int n_var = 9;
  int i, j, *ival;
  for (i = 0; i < n_var; i++) {
    double *dval;
    if ( (dval = (double *)calloc(n, sizeof(double))) == (double*)NULL) {
      fprintf(stderr, "ERROR could not allocate %d doubles\n", n);
      exit(22);
    }
    for (j = 0; j < n; j++) {
      dval[j] = 0.;
    }
    *dbl_ptrs[i] = dval;
  }
  if ((ival = (int *)calloc(n, sizeof(int))) == (int*)NULL) {
    fprintf(stderr, "ERROR could not allocate %d integers\n", n);
    exit(22);
  }
  for (j = 0; j < n; j++) {
    ival[j] = 0;
  }
  *nsamples = ival;
}

void
parse_args(int argc, char **argv, char **outfile, char **infile, 
   char **var1, char **var2, 
   double *north, double *south, double *east, double *west, 
   long *epoch, int *verbose)
{
    int i, j, n;
    char **instrings;
    char dtype;
    for (i = 1; i < argc; i++) {
        if (argv[i][0] != '-') break;
        switch(argv[i][1]) {
          case 'x':
              *var1 = strdup(argv[++i]);
              break;
          case 'y':
              *var2 = strdup(argv[++i]);
              break;
          case 'w':
              *west = atof(argv[++i]);
              break;
          case 'e':
              *east = atof(argv[++i]);
              break;
          case 's':
              *south = atof(argv[++i]);
              break;
          case 'n':
              *north = atof(argv[++i]);
              break;
          case 'i':
              *infile = strdup(argv[++i]);
              break;
          case 'o':
              *outfile = strdup(argv[++i]);
              break;
          case 't':
              *epoch = atol(argv[++i]);
              break;
          case 'v':
              *verbose = atoi(argv[++i]);
              break;
          default:
              usage();
              break;
        }
    }
    if (!*outfile) usage_error("Must specify an output file (-o)\n");
    if (!*infile) usage_error("Must specify an input file (-i)\n");
    if (!*var1) usage_error("Must specify variable name for X (-x)\n");
    if (!*var2 && *epoch < 0) usage_error("Must specify either variable name for Y (-y) or epoch time (-t) for time regression\n");
    return;
}
void usage_error(char *s) {
    fputs(s, stderr);
    usage();
}
void usage (){
    fprintf(stderr, 
"nccorrelate \n\
      -o outfile\n\
      -i input_file\n\
      -x x_variable\n\
      [-y y_variable]\n\
      [-t epoch]\n\
      [-n north_edge]\n\
      [-s south_edge]\n\
      [-e east_edge]\n\
      [-w west_edge]\n\
");
    exit(1);
}
