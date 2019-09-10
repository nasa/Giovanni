/*
 * NAME
 *   run_nccorrelate_test - unit test for the nccorrelate executable
 *
 * SYNOPSIS
 *   t_nccorrelate
 *   int run_nccorrelate_test (char *ref_file, char *cmd_root, char *root1, char *root2, int n_pairs, char *outnc_file)
 *
 * DESCRIPTION
 *   Runs the unit test for the nccorrelate executable. The "answers"
 *   have been checked by manual/spreadsheet calculations.
 *
 *   The procedure is:
 *   1) Convert input files from CDL to netcdf
 *   2) Write the paths to $TMPDIR/filelist.txt
 *   3) Call nccorrelate
 *   4) Rename the resultant output file to $TMPDIR/t_nccorrelate.nc.cmp*
 *   5) Convert the reference CDL file, e.g., t_nccorrelate.cdl, to netcdf.
 *   6) Diff the two files
 *
 *   *This renaming is needed because ncgen names the netCDF "object" in
 *    the netcdf file by the filename, regardless of what it says in the CDL.
 *
 * FILES
 *   Input: e.g., $TMPDIR/MOD08_[1-4].nc, $TMPDIR/MYD08_[1-4].nc
 *   Output: $TMPDIR/t_nccorrelate.nc.cmp
 *   Reference: $TMPDIR/t_nccorrelate.nc
 *
 * AUTHOR
 *   Chris Lynnes
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <netcdf.h>
#include "nccorrelate.h"


int
run_nccorrelate_test (char *ref_file, char *cmd_root, char *root1, char *root2, int n_pairs, int start, char *outnc_file)
{
  int i, j;
  char *cmd;
  char *outnc_path;
  char *filelist_path;
  char *ref_path;
  char *filelist = "files.txt";
  char *file1[n_pairs], *file2[n_pairs];
  char *filename;
  char *outdir;
  char *dot = ".";
  int rc;
  FILE *fp;

  /* Create reference file */
  ref_path = cdl2nc(ref_file, outnc_file);

  /* Output directory is TMPDIR if set, or cwd if not */
  outdir = getenv("TMPDIR");
  if (outdir == NULL) outdir = dot;

  /* Set up file list for writing */
  filelist_path = malloc(strlen(filelist)+strlen(outdir)+9);
  sprintf(filelist_path, "%s/%s.XXXXXX", outdir, filelist);
  if (mkstemp(filelist_path) == -1) {
    fprintf(stderr, "Error forming temp filename %s:", filelist_path);
    perror(NULL);
    exit (2);
  }
  if ((fp = (FILE *)fopen(filelist_path, "w")) == (FILE *)NULL) {
    perror("Error opening filelist");
    exit(2);
  }

  /* convert input ncfiles */
  filename = malloc(strlen(root1)+6);
  for (i = 0, j=start; i < n_pairs; i++,j++) {
    sprintf(filename, "%s%d.cdl", root1, j);
    file1[i] = cdl2nc(filename, NULL);
    sprintf(filename, "%s%d.cdl", root2, j);
    file2[i] = cdl2nc(filename, NULL);
    fprintf(fp, "%s %s\n", file1[i], file2[i]);
  }

  /* CLOSE the FILE so nccorrelate can read it! */
  fclose(fp);
  /* Form output pathname */
  outnc_path = malloc(strlen(outnc_file) + strlen(outdir) + 9);
  sprintf(outnc_path, "%s/%s.XXXXXX", outdir, outnc_file);
  if (mkstemp(outnc_path) == -1) {
    fprintf(stderr, "Could not form temporary file %s\n", outnc_path);
    perror(NULL);
    exit(2);
  }

  /* Form command line call */
  cmd = malloc(strlen(cmd_root) + 4 + strlen(filelist_path) + 4 + strlen(outnc_path) + 2);
  sprintf(cmd, "%s -i %s -o %s", cmd_root, filelist_path, outnc_path);
  fprintf(stderr, "cmd: %s\n", cmd);

  /* Execute command */
  system_call(cmd);
  fprintf(stderr, "Running %s\n", cmd);
  
  cdldiff(ref_path, outnc_path);

  /* Cleanup */
  if (getenv("SAVE_TEST_FILES")) exit(0);
  unlink(filelist_path);
  for (i = 0; i < n_pairs; i++) {
    unlink(file1[i]);
    unlink(file2[i]);
  }
  if (unlink(outnc_path)) fprintf(stderr, "Failed to unlink %s\n", outnc_path);
  if (unlink(outnc_path)) fprintf(stderr, "Failed to unlink %s\n", outnc_path);
  if (unlink(ref_path)) fprintf(stderr, "Failed to unlink %s\n", ref_path);
}
