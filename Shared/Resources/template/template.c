#include <stdio.h>
#include <stdlib.h>

int items[10] = {35, 95, 74, 71, 72, 30, 96, 53, 9, 0};

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

void printList(int items[], int size) {
  for (int i = 0; i < size; i++) {
    if (i == 0) {
      printf("[%d, ", items[i]);
    } else if (i != size - 1) {
      printf("%d, ", items[i]);
    } else {
      printf("%d]", items[i]);
    }
  }
}

/* TODO: Insert C algorithm implementation here. */

int main(int argc, char *argv[]) {
  int size = sizeof(items) / sizeof(items[0]);
  sort(items, size);
  printList(items, size);
  return 0;
}
