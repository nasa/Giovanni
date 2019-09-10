#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "nccorrelate.h"

static double going_up[] = {1., 2., 3., 4., 5., 6., 7., 8., 9., 10.};
static double going_down[] = {10., 9., 8., 7., 6., 5., 4., 3., 2., 1.};
static double big_upper = 11.2;
static double big_lower = 0.2;
static double medium_upper = 6.5;
static double medium_lower = 2.3;
static double small_upper = 4.2;
static double small_lower = 4.1;
static double high_outside_upper = 12.1;
static double high_outside_lower = 11.1;

int main(int argc, char **argv) {
  size_t start, count;
  double keep[10];

  /* Bounding box includes all coords */
  count = in_or_out(big_lower, big_upper, going_up, 10, &start, keep, 1);
  assert(start == 0);
  assert(count == 10);
  assert(keep[0] = going_up[0]);
  count = in_or_out(big_lower, big_upper, going_down, 10, &start, keep, 1);
  assert(start == 0);
  assert(count == 10);
  assert(keep[0] = going_up[0]);

  /* bounding box contains 4 coordinate points */
  count = in_or_out(medium_lower, medium_upper, going_up, 10, &start, keep, 1);
  assert(start == 2);
  assert(count == 4);
  assert(keep[0] = going_up[2]);
  count = in_or_out(medium_lower, medium_upper, going_down, 10, &start, keep, 1);
  assert(start == 4);
  assert(count == 4);
  assert(keep[0] = going_up[4]);

  /* Bounding box is contained between adjacent coordinates */
  count = in_or_out(small_lower, small_upper, going_up, 10, &start, keep, 3);
  assert(count == 1);
  assert(start == 3);
  assert(keep[0] = going_up[3]);
  count = in_or_out(small_lower, small_upper, going_down, 10, &start, keep, 3);
  assert(count == 1);
  assert(start == 6);
  assert(keep[0] = going_up[6]);

  /* Bounding box is completely outside coordinates */
  count = in_or_out(high_outside_lower, high_outside_upper, going_up, 10, &start, keep, 1);
  assert(count == 0);
}
