#include <signal.h>
#include <time.h>

int main(void) {
  signal(SIGTERM, SIG_DFL);
  struct timespec started, now;
  clock_gettime(CLOCK_MONOTONIC, &started);
  volatile unsigned long accumulator = 0;
  do {
    for (unsigned long i = 0; i < 1000000; i++) accumulator += i;
    clock_gettime(CLOCK_MONOTONIC, &now);
  } while ((now.tv_sec - started.tv_sec) < 30);
  return accumulator == 0;
}
