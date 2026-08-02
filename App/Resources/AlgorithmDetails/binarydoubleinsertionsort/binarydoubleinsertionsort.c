#include <stdio.h>

int leftBinarySearch(int *array, int a, int b, int val) {
  int lo = a, hi = b;
  while (lo < hi) {
    int mid = lo + (hi - lo) / 2;
    if (val <= array[mid]) {
      hi = mid;
    } else {
      lo = mid + 1;
    }
  }
  return lo;
}

int rightBinarySearch(int *array, int a, int b, int val) {
  int lo = a, hi = b;
  while (lo < hi) {
    int mid = lo + (hi - lo) / 2;
    if (val < array[mid]) {
      hi = mid;
    } else {
      lo = mid + 1;
    }
  }
  return lo;
}

void insertToLeft(int *array, int a, int b, int temp) {
  while (a > b) {
    array[a] = array[a - 1];
    a--;
  }
  array[b] = temp;
}

void insertToRight(int *array, int a, int b, int temp) {
  while (a < b) {
    array[a] = array[a + 1];
    a++;
  }
  array[a] = temp;
}

void doubleInsertion(int *array, int a, int b) {
  if (b - a < 2) {
    return;
  }

  int j = a + (b - a - 2) / 2 + 1;
  int i = a + (b - a - 1) / 2;

  if (j > i && array[i] > array[j]) {
    int tmp = array[i];
    array[i] = array[j];
    array[j] = tmp;
  }
  i--;
  j++;

  while (j < b) {
    if (array[i] > array[j]) {
      int l = array[j];
      int r = array[i];
      int m = rightBinarySearch(array, i + 1, j, l);
      insertToRight(array, i, m - 1, l);
      int dest = leftBinarySearch(array, m, j, r);
      insertToLeft(array, j, dest, r);
    } else {
      int l = array[i];
      int r = array[j];
      int m = leftBinarySearch(array, i + 1, j, l);
      insertToRight(array, i, m - 1, l);
      int dest = rightBinarySearch(array, m, j, r);
      insertToLeft(array, j, dest, r);
    }
    i--;
    j++;
  }
}

void sort(int *arr, int n) {
  if (n > 1) {
    doubleInsertion(arr, 0, n);
  }
}

int main(void) {
  int array[] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
  int n = sizeof(array) / sizeof(array[0]);
  sort(array, n);

  printf("[");
  for (int i = 0; i < n; i++) {
    printf("%d", array[i]);
    if (i != n - 1) {
      printf(", ");
    }
  }
  printf("]\n");
  return 0;
}
