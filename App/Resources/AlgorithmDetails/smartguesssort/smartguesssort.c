#include <stdio.h>
#include <stdlib.h>

int array[7] = {0, 39, 21, 62, 91, 14, 23};

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

int pairOk(int arr[], int loops[], int i) {
  int a = arr[loops[i]];
  int b = arr[loops[i + 1]];
  if (a < b) {
    return 1;
  }
  if (a == b && loops[i] < loops[i + 1]) {
    return 1;
  }
  return 0;
}

int firstFailure(int arr[], int loops[], int n) {
  int i = n - 2;
  while (i >= 0 && pairOk(arr, loops, i)) {
    i--;
  }
  return i;
}

void sort(int arr[], int n) {
  int loops[n];
  int mapped[n];
  for (int i = 0; i < n; i++) {
    loops[i] = 0;
  }

  while (1) {
    int i = firstFailure(arr, loops, n);
    if (i < 0) {
      break;
    }
    for (int pos = 0; pos < n; pos++) {
      if (pos >= i && loops[pos] < n - 1) {
        loops[pos] += 1;
        break;
      } else {
        loops[pos] = 0;
      }
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
