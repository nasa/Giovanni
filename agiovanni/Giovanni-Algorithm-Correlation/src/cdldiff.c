#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int cdldiff(char *path1, char *path2)
{
  char *template = "ncdump %s | tail -n +2 > %s/out1 && ncdump %s | tail -n +2 > %s/out2 && diff %s/out1 %s/out2 && /bin/rm %s/out1 %s/out2";
  char *outdir, *cmd;
  int rc;
  outdir = getenv("TMPDIR");
  if (outdir == NULL) outdir = strdup(".");
  cmd = malloc(strlen(template) + 6 * strlen(outdir) + strlen(path1) + strlen(path2));
  sprintf(cmd, template, path1, outdir, path2, outdir, outdir, outdir, outdir, outdir);
  rc = system(cmd);
  if (rc == 0) {
    fprintf(stderr, "INFO successful comparison with %s\n", cmd);
  }
  else {
    fprintf(stderr, "ERROR on cmd %s: %d\n", cmd, rc);
    exit(2);
  }
  return 1;
}
