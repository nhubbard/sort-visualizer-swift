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
  printf("[");
  if (size > 0) {
    printf("%d", items[0]);
    for (int i = 1; i < size; i++) {
      printf(", %d", items[i]);
    }
  }
  printf("]");
}

void flip(int arr[], int n);
int maxIndex(int arr[], int n);

void sort(int arr[], int n) {
  int max;
  while (n > 1) {
    max = maxIndex(arr, n);
    if (max != n - 1) {
      flip(arr, max);
      flip(arr, n - 1);
    }
    n--;
  }
}

void flip(int arr[], int n) {
  int left = 0;
  while (left < n) {
    swap(&arr[left], &arr[n]);
    n--;
    left++;
  }
}

int maxIndex(int arr[], int n) {
  int index = 0;
  for (int i = 0; i < n; i++) {
    if (arr[i] > arr[index]) {
      index = i;
    }
  }
  return index;
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
