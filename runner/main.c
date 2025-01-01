#include <libgen.h>
#include <limits.h> /* PATH_MAX */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char **argv) {
  // Also consider readlink(2)?
  char *binary_path = realpath(argv[0], NULL);
  if (binary_path == NULL) {
    fprintf(stderr, "Failed to find path to binary.\n");
    abort();
  }
  char *dir_path = dirname(binary_path);
  free(binary_path);
  char find_path[PATH_MAX];
  sprintf(find_path, "%s/find", dir_path);

  int ch = -1;

  while ((ch = getopt(argc, argv, "")) != -1) {
    switch (ch) {
    // TODO
    default:
      break;
    }
  }

  // count of unparsed args
  argc -= optind;
  // next unparsed arg
  argv += optind;

  execvp(find_path, argv);

  fprintf(stderr, "execvp(%s) failed!\n", find_path);
  abort();
}
