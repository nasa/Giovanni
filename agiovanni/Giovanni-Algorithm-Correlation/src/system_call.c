#include <stdlib.h>
#include <stdio.h>
int
system_call(char *cmd)
{
  int rc;
  rc = system(cmd);
  fprintf(stderr, "%s\n", cmd);
  if (rc & 127) {
    fprintf(stderr, "Signal received: %d\n", rc&127);
    exit(1);
  }
  else if (rc & 128) {
    fprintf(stderr, "Dumped core\n");
    exit(2);
  }
  else if (rc != 0) {
    fprintf(stderr, "Non-zero exit code: %d\n", (rc >> 8));
    exit(rc >> 8);
  }
  else if (rc == 0) {
    fprintf(stderr, "Succeeded\n");
  }
  else {
    /* Did we miss any cases? */
    exit(3);
  }
}
