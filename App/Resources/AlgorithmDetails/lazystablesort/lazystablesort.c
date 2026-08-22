#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

void swap(int arr[], int a, int b) {
  int t = arr[a];
  arr[a] = arr[b];
  arr[b] = t;
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

void multiSwap(int arr[], int a, int b, int count) {
  for (int i = 0; i < count; i++)
    swap(arr, a + i, b + i);
}

void rotate(int arr[], int pos, int lenA, int lenB) {
  while (lenA != 0 && lenB != 0) {
    if (lenA <= lenB) {
      multiSwap(arr, pos, pos + lenA, lenA);
      pos += lenA;
      lenB -= lenA;
    } else {
      multiSwap(arr, pos + (lenA - lenB), pos + lenA, lenB);
      lenA -= lenB;
    }
  }
}

int binSearch(int arr[], int pos, int len, int keyPos, int isLeft) {
  int left = 0, right = len;
  while (left < right) {
    int mid = left + (right - left) / 2;
    int cond = isLeft ? (arr[pos + mid] < arr[keyPos])
                      : (arr[pos + mid] <= arr[keyPos]);
    if (cond)
      left = mid + 1;
    else
      right = mid;
  }
  return left;
}

void mergeWithoutBuffer(int arr[], int pos, int len1, int len2) {
  if (len1 == 0 || len2 == 0)
    return;
  if (len1 == 1) {
    int loc = binSearch(arr, pos + 1, len2, pos, 1);
    rotate(arr, pos, 1, loc);
    return;
  }
  if (len2 == 1) {
    int loc = binSearch(arr, pos, len1, pos + len1, 0);
    rotate(arr, pos + loc, len1 - loc, 1);
    return;
  }
  int mid1 = len1 / 2;
  int loc = binSearch(arr, pos + len1, len2, pos + mid1, 1);
  rotate(arr, pos + mid1, len1 - mid1, loc);
  mergeWithoutBuffer(arr, pos, mid1, loc);
  mergeWithoutBuffer(arr, pos + mid1 + loc, len1 - mid1, len2 - loc);
}

void sort(int arr[], int n) {
  int dist = 1;
  while (dist < n) {
    if (arr[dist - 1] > arr[dist])
      swap(arr, dist - 1, dist);
    dist += 2;
  }
  int part = 2;
  while (part < n) {
    int left = 0;
    int right = n - 2 * part;
    while (left <= right) {
      mergeWithoutBuffer(arr, left, part, part);
      left += 2 * part;
    }
    int rest = n - left;
    if (rest > part)
      mergeWithoutBuffer(arr, left, part, rest - part);
    part *= 2;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
