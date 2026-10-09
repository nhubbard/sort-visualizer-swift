#include <stdio.h>

__attribute__((constructor)) static void announce_injection(void) {
  fprintf(stderr, "INSTRUMENTS_INJECTION_PROBE_LOADED\n");
}
