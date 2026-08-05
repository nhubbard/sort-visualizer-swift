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

/* Selects the c smallest combined elements of the two already-sorted runs
   [a, m) and [m, b) into the front half via a single rotation. Uses a
   merge-path (co-rank) binary search over whichever run is shorter: it
   looks for the split count r such that taking r elements from the tail of
   one run and (c - r) from the head of the other yields exactly the c
   smallest values in order, rather than searching for a value directly. */
void partitionMerge(int arr[], int a, int m, int b, int c) {
  int lenA = m - a, lenB = b - m;
  if (lenA < 1 || lenB < 1)
    return;

  if (lenB < lenA) {
    int cc = (lenA + lenB) - c;
    int r1 = cc - lenA > 0 ? cc - lenA : 0;
    int r2 = cc < lenB ? cc : lenB;
    while (r1 < r2) {
      int ml = r1 + (r2 - r1) / 2;
      if (arr[m - (cc - ml)] > arr[b - ml - 1]) {
        r2 = ml;
      } else {
        r1 = ml + 1;
      }
    }
    rotate(arr, m - (cc - r1), m, b - r1);
  } else {
    int r1 = c - lenB > 0 ? c - lenB : 0;
    int r2 = c < lenA ? c : lenA;
    while (r1 < r2) {
      int ml = r1 + (r2 - r1) / 2;
      if (arr[a + ml] > arr[m + (c - ml) - 1]) {
        r2 = ml;
      } else {
        r1 = ml + 1;
      }
    }
    rotate(arr, a + r1, m, m + (c - r1));
  }
}

/* Finds the first place inside [a, b) where ascending order breaks, then
   partition-merges the sorted piece before it with the sorted piece after
   it. A no-op if [a, b) is already one ascending run. */
void rotateMerge(int arr[], int a, int b, int c) {
  int i = a + 1;
  while (i < b && arr[i - 1] <= arr[i])
    i++;
  if (i < b)
    partitionMerge(arr, a, i, b, c);
}

void rotatePartitionMergeSort(int arr[], int n) {
  if (n < 2)
    return;

  for (int i = 1; i < n; i += 2) {
    if (arr[i - 1] > arr[i]) {
      int t = arr[i - 1];
      arr[i - 1] = arr[i];
      arr[i] = t;
    }
  }

  for (int j = 2; j < n; j *= 2) {
    int b1 = 0;
    int blockStart = 0;
    while (blockStart + j < n) {
      b1 = blockStart + 2 * j < n ? blockStart + 2 * j : n;
      partitionMerge(arr, blockStart, blockStart + j, b1, j);
      blockStart += 2 * j;
    }

    for (int k = j / 2; k > 1; k /= 2) {
      int seamStart = 0;
      while (seamStart + k < b1) {
        int seamEnd = seamStart + 2 * k < n ? seamStart + 2 * k : n;
        rotateMerge(arr, seamStart, seamEnd, k);
        seamStart += 2 * k;
      }
    }

    for (int m = 1; m < b1; m += 2) {
      if (arr[m - 1] > arr[m]) {
        int t = arr[m - 1];
        arr[m - 1] = arr[m];
        arr[m] = t;
      }
    }
  }
}

void sort(int arr[], int n) { rotatePartitionMergeSort(arr, n); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
