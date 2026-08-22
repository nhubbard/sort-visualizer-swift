#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

int intPow(int base, int exponent) {
  int result = 1;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}

int getDigit(int value, int place, int base) {
  return (value / intPow(base, place)) % base;
}

void multiSwap(int arr[], int a, int b, int len) {
  for (int i = 0; i < len; i++) {
    int t = arr[a + i];
    arr[a + i] = arr[b + i];
    arr[b + i] = t;
  }
}

void rotateBlocks(int arr[], int a, int m, int b) {
  int l = m - a;
  int r = b - m;
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

int binSearchDigit(int arr[], int a, int b, int d, int place, int base) {
  while (a < b) {
    int mid = (a + b) / 2;
    if (getDigit(arr[mid], place, base) >= d) {
      b = mid;
    } else {
      a = mid + 1;
    }
  }
  return a;
}

void mergeDigit(int arr[], int a, int m, int b, int da, int db, int place,
                int base) {
  if (b - a < 2 || db - da < 2) {
    return;
  }
  int dm = (da + db) / 2;
  int m1 = binSearchDigit(arr, a, m, dm, place, base);
  int m2 = binSearchDigit(arr, m, b, dm, place, base);
  rotateBlocks(arr, m1, m, m2);
  int newM = m1 + (m2 - m);
  mergeDigit(arr, newM, m2, b, dm, db, place, base);
  mergeDigit(arr, a, m1, newM, da, dm, place, base);
}

void mergeSortDigit(int arr[], int a, int b, int place, int base) {
  if (b - a < 2) {
    return;
  }
  int mid = (a + b) / 2;
  mergeSortDigit(arr, a, mid, place, base);
  mergeSortDigit(arr, mid, b, place, base);
  mergeDigit(arr, a, mid, b, 0, base, place, base);
}

/* Digit-sorts [a, b) in place by `place` using rotation instead of counting
 * buckets, then recurses into every resulting digit bucket one place lower --
 * an ordinary MSD radix sort built entirely out of the LSD variant's
 * rotate/binary-search machinery. */
void msdRotateSort(int arr[], int a, int b, int place, int base) {
  if (b - a < 2 || place < 0) {
    return;
  }
  mergeSortDigit(arr, a, b, place, base);
  int start = a;
  for (int d = 0; d < base; d++) {
    int end = binSearchDigit(arr, start, b, d + 1, place, base);
    msdRotateSort(arr, start, end, place - 1, base);
    start = end;
  }
}

void sort(int arr[], int n) {
  if (n <= 1) {
    return;
  }
  int base = 4;
  int maxValue = arr[0];
  for (int i = 1; i < n; i++) {
    if (arr[i] > maxValue) {
      maxValue = arr[i];
    }
  }
  int highestPlace = 0;
  int probe = base;
  while (probe <= maxValue) {
    highestPlace++;
    probe *= base;
  }
  msdRotateSort(arr, 0, n, highestPlace, base);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
