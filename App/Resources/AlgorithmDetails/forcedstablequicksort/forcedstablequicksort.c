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

int stableComp(int arr[], int key[], int a, int b) {
  if (arr[a] > arr[b]) return 1;
  if (arr[a] == arr[b]) return key[a] > key[b];
  return 0;
}

void stableSwap(int arr[], int key[], int a, int b) {
  swap(&arr[a], &arr[b]);
  swap(&key[a], &key[b]);
}

void medianOfThree(int arr[], int key[], int a, int b) {
  int m = a + (b - 1 - a) / 2;
  if (stableComp(arr, key, a, m)) stableSwap(arr, key, a, m);
  if (stableComp(arr, key, m, b - 1)) {
    stableSwap(arr, key, m, b - 1);
    if (stableComp(arr, key, a, m)) return;
  }
  stableSwap(arr, key, a, m);
}

int partition(int arr[], int key[], int a, int b, int p) {
  int i = a - 1;
  int j = b;
  while (1) {
    do {
      i++;
    } while (i < j && !stableComp(arr, key, i, p));
    do {
      j--;
    } while (j >= i && stableComp(arr, key, j, p));
    if (i < j) {
      stableSwap(arr, key, i, j);
    } else {
      return j;
    }
  }
}

void quickSort(int arr[], int key[], int a, int b) {
  if (b - a < 3) {
    if (b - a == 2 && stableComp(arr, key, a, a + 1)) {
      stableSwap(arr, key, a, a + 1);
    }
    return;
  }
  medianOfThree(arr, key, a, b);
  int p = partition(arr, key, a + 1, b, a);
  stableSwap(arr, key, a, p);
  quickSort(arr, key, a, p);
  quickSort(arr, key, p + 1, b);
}

void sort(int arr[], int n) {
  int *key = malloc(sizeof(int) * n);
  for (int i = 0; i < n; i++) key[i] = i;
  quickSort(arr, key, 0, n);
  free(key);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}