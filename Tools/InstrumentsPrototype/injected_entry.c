#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

extern int instruments_swift_entry(void);

// DYLD injection gives the prototype the xctrace process's Apple signature and
// private-framework authorization. Consume the marker and library variables so
// targets spawned by the recorder do not recursively load this dylib. _exit
// prevents xctrace's normal CLI entry point from running after our host exits.
__attribute__((constructor)) static void run_instruments_probe_if_requested(void) {
  if (strcmp(getenv("INSTRUMENTS_INJECT_RUN") ?: "", "1") != 0) return;
  unsetenv("DYLD_INSERT_LIBRARIES");
  unsetenv("INSTRUMENTS_INJECT_RUN");
  int status = instruments_swift_entry();
  fprintf(stderr, "injected probe status: %d\n", status);
  fflush(stderr);
  _exit(status);
}
