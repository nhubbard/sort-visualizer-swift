#include <stdio.h>

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

int leftBinarySearch(int *array, int a, int b, int val);
int rightBinarySearch(int *array, int a, int b, int val);
void insertToLeft(int *array, int a, int b, int temp);
void insertToRight(int *array, int a, int b, int temp);
void doubleInsertion(int *array, int a, int b);

void sort(int *arr, int n) {
  if (n > 1) {
    doubleInsertion(arr, 0, n);
  }
}

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

int main(void) {
  int n = sizeof(array) / sizeof(array[0]);
  sort(array, n);

  printList(array, n);
  return 0;
}
