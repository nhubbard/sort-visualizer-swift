#include <stdio.h>
#include <stdlib.h>

int array[7] = {0, 39, 21, 62, 91, 14, 23};

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

int pairOk(int arr[], int loops[], int i);
int firstFailure(int arr[], int loops[], int n);

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

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
