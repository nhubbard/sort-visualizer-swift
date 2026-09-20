#include <stdio.h>
#include <stdlib.h>

int array[5] = {0, 39, 21, 62, 14};

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

void printList(int items[], int size) {
  printf("[");
  if (size > 0) {
    printf("%d", items[0]);
    for (int i = 1; i < size; i++) {
      printf(", %d", items[i]);
    }
  }
  printf("]");
}

void sort(int arr[], int n) {
  if (n <= 1) return;
  int loops[n];
  int mapped[n];
  for (int i = 0; i < n; i++) {
    loops[i] = 0;
  }
  while (1) {
    int isSorted = 1;
    for (int i = 0; i < n - 1; i++) {
      int a = arr[loops[i]];
      int b = arr[loops[i + 1]];
      if (a < b || (a == b && loops[i] < loops[i + 1])) {
        continue;
      }
      isSorted = 0;
      break;
    }
    if (isSorted) {
      break;
    }
    for (int pos = 0; pos < n; pos++) {
      if (loops[pos] < n - 1) {
        loops[pos]++;
        break;
      }
      loops[pos] = 0;
    }
  }

  for (int i = 0; i < n; i++) {
    mapped[i] = arr[loops[i]];
  }
  for (int i = 0; i < n; i++) {
    arr[i] = mapped[i];
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
