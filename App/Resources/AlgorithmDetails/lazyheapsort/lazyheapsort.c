#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

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

void maxToFront(int arr[], int a, int b) {
  int best = a;
  int i = a + 1;
  while (i < b) {
    if (arr[i] > arr[best]) {
      best = i;
    }
    i += 1;
  }
  int t = arr[best];
  arr[best] = arr[a];
  arr[a] = t;
}

void sort(int arr[], int n) {
  int s = (int)sqrt((double)(n - 1)) + 1;

  int i = 0;
  while (i < n) {
    int end = (i + s < n) ? i + s : n;
    maxToFront(arr, i, end);
    i += s;
  }

  int j = n;
  while (j > 0) {
    int best = 0;
    int k = best + s;
    while (k < j) {
      if (arr[k] >= arr[best]) {
        best = k;
      }
      k += s;
    }
    j -= 1;
    int t = arr[best];
    arr[best] = arr[j];
    arr[j] = t;
    int end2 = (best + s < j) ? best + s : j;
    maxToFront(arr, best, end2);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
