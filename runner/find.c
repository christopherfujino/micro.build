#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char **argv) {
  char *name = NULL;
  int opt_idx = -1;
  struct option opts[] = {
      // required_argument means there must be a subsequent argument
      {"name", required_argument, NULL, 'n'},
      {NULL, 0, NULL, 0}};

  int ch = -1;

  // colon means an argument follows
  while ((ch = getopt_long(argc, argv, "n:", opts, &opt_idx)) != -1) {
    switch (ch) {
    case 'n':
      fprintf(stderr, "n -> %s\n", optarg);
      name = optarg;
      break;
    case '?':
      fprintf(stderr, "?\n");
      abort();
    // 0 means long option passed...
    case 0:
      abort();
      break;
    // TODO
    default:
      fprintf(stderr, "ch was: %d\n", ch);
      abort();
    }
  }

  // count of unparsed args
  argc -= optind;
  // next unparsed arg
  argv += optind;

  if (name == NULL) {
    fprintf(stderr, "Usage: find --name pattern\n");
    abort();
  }

  printf("Looking for the entity \"%s\"...\n", name);

  return 0;
}
