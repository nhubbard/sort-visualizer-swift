#include <fcntl.h>
#include <stdio.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

// Produces repeatable file operations for the File Activity template probe.
int main(void) {
  const char *path = "/private/tmp/instruments-file-activity-fixture";
  for (int index = 0; index < 4000; index++) {
    int fd = open(path, O_CREAT | O_RDWR | O_TRUNC, 0600);
    if (fd < 0) return 1;
    if (write(fd, "trace\n", 6) != 6) return 2;
    if (lseek(fd, 0, SEEK_SET) < 0) return 3;
    char buffer[6];
    if (read(fd, buffer, sizeof(buffer)) != sizeof(buffer)) return 4;
    close(fd);
    usleep(1000);
  }
  unlink(path);
  return 0;
}
