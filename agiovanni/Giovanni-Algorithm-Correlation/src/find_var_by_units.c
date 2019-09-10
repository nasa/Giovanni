/*
 * NAME
 *
 * SYNOPSIS 
 *
 * DESCRIPTION 
 *
 * AUTHOR
 *  Chris Lynnes, NASA/GSFC
 *
 * $Id: find_var_by_units.c,v 1.2 2012/06/25 21:55:52 clynnes Exp $
 * -@@@ Giovanni, Version $Name:  $
 */
int find_var_by_units(int ncid, char *units)
{
  int nvars, status, attid;
  int i;
  size_t attlen;
  char *buf = NULL;
  if ((status = nc_inq_nvars(ncid, &nvars)) != NC_NOERR) {
    fprintf(stderr, "ERROR failed to get number of variables\n");
    exit(4);
  }
  /* Look for canonical units, e.g, "degrees_east" or "degrees_north" */
  for (i = 0; i < nvars; i++) {
    status = nc_inq_attid(ncid, i, "units", &attid);
    if (status == NC_NOERR) {
      fprintf(stderr, "DEBUG found attribute for units %s in varid %d\n", units, i);
      status = nc_inq_attlen(ncid, i, "units", &attlen);
      buf = malloc(attlen + 1);
      status = nc_get_att_text(ncid, i, "units", buf);
      if (strcmp(buf, units) == 0) {
        fprintf(stderr, "DEBUG found variable %d with units %s\n", i, units);
        return i;
      }
    }
  }
  fprintf(stderr, "Could not find variable with units %s\n", units);
  exit(4);
}
