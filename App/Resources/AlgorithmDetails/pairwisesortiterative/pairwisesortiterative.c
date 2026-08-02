#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

void printList(int arr[], int n) {
  for (int i = 0; i < n; i++) {
    if (i == 0) {
      printf("[%d, ", arr[i]);
    } else if (i != n - 1) {
      printf("%d, ", arr[i]);
    } else {
      printf("%d]", arr[i]);
    }
  }
  printf("\n");
}

void sort(int arr[], int length) {
  int a = 1;
  while (a < length) {
    int b = a;
    int c = 0;
    while (b < length) {
      if (arr[b - a] > arr[b]) {
        int temp = arr[b - a];
        arr[b - a] = arr[b];
        arr[b] = temp;
      }
      c = (c + 1) % a;
      b++;
      if (c == 0)
        b += a;
    }
    a *= 2;
  }

  a /= 4;
  int e = 1;
  while (a > 0) {
    int d = e;
    while (d > 0) {
      int b = (d + 1) * a;
      int c = 0;
      while (b < length) {
        if (arr[b - (d * a)] > arr[b]) {
          int temp = arr[b - (d * a)];
          arr[b - (d * a)] = arr[b];
          arr[b] = temp;
        }
        c = (c + 1) % a;
        b++;
        if (c == 0)
          b += a;
      }
      d /= 2;
    }
    a /= 2;
    e = (e * 2) + 1;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
