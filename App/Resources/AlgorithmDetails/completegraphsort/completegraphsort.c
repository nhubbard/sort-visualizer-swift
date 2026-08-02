#include <math.h>
#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

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

void compSwap(int arr[], int a, int b) {
  if (arr[a] > arr[b]) swap(&arr[a], &arr[b]);
}

void split(int arr[], int a, int m, int b) {
  if (b - a < 2) return;
  int c = 0, len1 = (b - a) / 2;
  int odd = (b - a) % 2 == 1;
  if (odd) {
    if (m - a > b - m) c = a++;
    else c = --b;
  }
  for (int s = 0; s < len1; s++) {
    int i = a;
    for (int j = s; j < len1; j++) compSwap(arr, i++, m + j);
    for (int j = 0; j < s; j++) compSwap(arr, i++, m + j);
  }
  if (odd) {
    if (c < m) {
      for (int j = 0; j < len1; j++) compSwap(arr, c, m + j);
    } else {
      for (int j = 0; j < len1; j++) compSwap(arr, a + j, c);
    }
  }
}

void sort(int arr[], int n) {
  int d = 2, end = 1 << (int)(log(n - 1) / log(2) + 1);
  while (d <= end) {
    int i = 0, dec = 0;
    while (i < n) {
      int j = i;
      dec += n;
      while (dec >= d) {
        dec -= d;
        j++;
      }
      int k = j;
      dec += n;
      while (dec >= d) {
        dec -= d;
        k++;
      }
      split(arr, i, j, k);
      i = k;
    }
    d *= 2;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
