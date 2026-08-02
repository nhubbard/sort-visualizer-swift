#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

int compositeLess(int arr[], int key[], int mid, int i) {
  if (arr[mid] < arr[i])
    return 1;
  if (arr[mid] == arr[i])
    return key[mid] < key[i];
  return 0;
}

int binarySearch(int arr[], int key[], int n, int i) {
  int start = 0;
  int end = n - 1;
  while (start < end) {
    int mid = (start + end) / 2;
    if (compositeLess(arr, key, mid, i)) {
      start = mid + 1;
    } else {
      end = mid;
    }
  }
  return start;
}

void sort(int arr[], int n) {
  int *key = malloc(n * sizeof(int));
  for (int i = 0; i < n; i++)
    key[i] = i;

  for (int i = 1; i < n; i++) {
    int done = 0;
    while (!done) {
      int pos = binarySearch(arr, key, n, i);
      if (pos == i) {
        done = 1;
      } else if (i < pos - 1) {
        swap(&arr[i], &arr[pos - 1]);
        swap(&key[i], &key[pos - 1]);
      } else {
        swap(&arr[i], &arr[pos]);
        swap(&key[i], &key[pos]);
      }
    }
  }

  free(key);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}