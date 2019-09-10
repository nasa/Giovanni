#include <stdlib.h>
#include <regex.h>
#include <stdio.h>
#include <string.h>
#define N_SUB_EXP  5  /* It's really 4, but we have to account for the whole string */

int
parse_varstring(char *varstring, char **varname, char **zdim, double *zval, char **zunits) {

  regex_t regex;
  char *expression = "(.*),(.*)=([0-9.]+)(.*)";
  regmatch_t match[N_SUB_EXP];
  int status;
  char *s, *zval_str;

  /* Compile regular expression */
  if ((status = regcomp(&regex, expression, REG_EXTENDED)) != 0) {
    fprintf(stderr, "ERROR failed to compile regex '%s' (status=%d)\n", expression, status);
    return -1;
  }

  /* Apply regular expression to varstring */
  status = regexec(&regex, varstring, N_SUB_EXP, match, 0);

  /* No match, no problem, just a 2-D variable */
  if (status == REG_NOMATCH) {
    *varname = varstring;
    return 0;
  }

  /* Parcel up the rest of the expression */
  *varname = strndup(varstring + match[1].rm_so, match[1].rm_eo-match[1].rm_so);
  *zdim = strndup(varstring + match[2].rm_so, match[2].rm_eo-match[2].rm_so);
  zval_str = strndup(varstring + match[3].rm_so, match[3].rm_eo-match[3].rm_so);
  *zval = atof(zval_str);
  *zunits = strndup(varstring + match[4].rm_so, match[4].rm_eo-match[4].rm_so);
  return 1;
}
