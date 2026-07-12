#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

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
}

void multiSwap(int arr[], int a, int b, int len) {
  for (int i = 0; i < len; i++) {
    int t = arr[a + i];
    arr[a + i] = arr[b + i];
    arr[b + i] = t;
  }
}

void rotate(int arr[], int a, int m, int b) {
  int l = m - a, r = b - m;
  while (l > 0 && r > 0) {
    if (r < l) {
      multiSwap(arr, m - r, m, r);
      b -= r;
      m -= r;
      l -= r;
    } else {
      multiSwap(arr, a, m, l);
      a += l;
      m += l;
      r -= l;
    }
  }
}

int binarySearch(int arr[], int a, int b, int value, int left) {
  while (a < b) {
    int mid = a + (b - a) / 2;
    int comp = left ? (value <= arr[mid]) : (value < arr[mid]);
    if (comp) {
      b = mid;
    } else {
      a = mid + 1;
    }
  }
  return a;
}

void rotateMerge(int arr[], int a, int m, int b) {
  int m1, m2, m3;
  if (m - a >= b - m) {
    m1 = a + (m - a) / 2;
    int value = arr[m1];
    m2 = binarySearch(arr, m, b, value, 1);
    m3 = m1 + (m2 - m);
  } else {
    m2 = m + (b - m) / 2;
    int value = arr[m2];
    m1 = binarySearch(arr, a, m, value, 0);
    m3 = m2 - (m - m1);
    m2 = m2 + 1;
  }
  rotate(arr, m1, m, m2);
  if (m2 - (m3 + 1) > 0 && b - m2 > 0) {
    rotateMerge(arr, m3 + 1, m2, b);
  }
  if (m1 - a > 0 && m3 - m1 > 0) {
    rotateMerge(arr, a, m1, m3);
  }
}

void rotateMergeSort(int arr[], int a, int b) {
  int len = b - a;
  int j = 1;
  while (j < len) {
    int i;
    for (i = a; i + 2 * j <= b; i += 2 * j) {
      rotateMerge(arr, i, i + j, i + 2 * j);
    }
    if (i + j < b) {
      rotateMerge(arr, i, i + j, b);
    }
    j *= 2;
  }
}

void sort(int arr[], int n) {
  rotateMergeSort(arr, 0, n);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
