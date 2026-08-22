#include <stdio.h>
#include <stdlib.h>

int array[4] = {0, 39, 21, 14};

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

int isValid(int arr[], int loops[], int n) {
  int total = 0;
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < n; j++) {
      if (loops[i] == loops[j]) {
        total += 1;
      }
    }
  }
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < n; j++) {
      if ((i < j && arr[loops[i]] > arr[loops[j]]) ||
          (i > j && arr[loops[i]] < arr[loops[j]])) {
        total += 1;
      }
    }
  }
  return total == n;
}

void sort(int arr[], int n) {
  int loops[n];
  int indexes[n];
  int original[n];
  for (int i = 0; i < n; i++) {
    loops[i] = 0;
    indexes[i] = 0;
  }

  while (1) {
    if (isValid(arr, loops, n)) {
      for (int i = 0; i < n; i++) {
        indexes[i] = loops[i];
      }
    }
    int pos = 0;
    while (pos < n) {
      if (loops[pos] < n - 1) {
        loops[pos] += 1;
        break;
      } else {
        loops[pos] = 0;
        pos += 1;
      }
    }
    if (pos == n) {
      break;
    }
  }

  for (int i = 0; i < n; i++) {
    original[i] = arr[i];
  }
  for (int i = 0; i < n; i++) {
    arr[i] = original[indexes[i]];
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
