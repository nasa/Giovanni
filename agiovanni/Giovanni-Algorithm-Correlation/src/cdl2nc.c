/*
 * NAME
 *  cdl2nc - convert CDL file to netCDF file with ncgen
 *
 * SYNOPSIS
 *  outpath = cdl2nc(
 *      pathname,     # Path of calling program
 *      output_name)  # Name of output netCDF file, sort of
 *
 * DESCRIPTION 
 *  cdl2nc converts a CDL file to a netCDF file with ncgen.
 *  The output filename is based on the basename of the CDL
 *  file, which is supplied via argv[0] from main, 
 *  but is written to $TMPDIR, if found in the environment.
 *  If TMPDIR is not set, it is written to the current directory.
 *  To prevent permission collisions, the netCDF file
 *  It returns the pathname of the output file.
 *
 * DIAGNOSTICS
 *  Failure to execute ncgen properly results in exit code 2.
 *
 * AUTHOR
 *  Chris Lynnes, NASA/GSFC
 *
 * $Id: cdl2nc.c,v 1.9 2013/11/15 18:43:56 clynnes Exp $ 
 * -@@@ Giovanni, Version $Name:  $
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

char *cdl2nc(char *ref_file, char *rename_file)
{
  char *basename = strrchr(ref_file, '/');    /* basename of the reference file or executable */
  char *ncgen = "ncgen ";
  char *outpath, *cmd;
  char *rename_path;
  int status;
  char *outdir;

  /* Use current directory if TMPDIR is not set */
  if ((outdir = getenv("TMPDIR")) == NULL) outdir = strdup(".");

  if (basename == NULL) basename = ref_file;

  outpath = malloc(strlen(basename) + strlen(outdir) + 13);
  if (rename_file == NULL) {
    sprintf(outpath, "%s/%s.nc.XXXXXX", outdir, basename);
  }
  else {
    sprintf(outpath, "%s/%s.XXXXXX", outdir, rename_file);
  }
  if (mkstemp(outpath) == -1) {
    fprintf(stderr, "Error generating temp file name based on %s:", outpath);
    perror(NULL);
    exit(2);
  }

  /* 
   * ncgen command: write it to the path indicated by netcdf_path
   * so that the internal object (which ncgen always names after the file's basename)
   * can be specified by the calling program 
   */
  cmd = malloc(strlen(ref_file) + strlen(ncgen) + strlen(outpath) + 6);
  sprintf(cmd, "%s -o %s %s", ncgen, outpath, ref_file);

  /* Create .nc file */
  status = system(cmd);
  if (status) {
    fprintf(stderr, "Error running %s: %d\n", cmd, status >> 8);
    exit(2);
  }
  fprintf(stderr, "Made netcdf file %s\n", outpath);
  free(cmd);
  return(outpath);
}
