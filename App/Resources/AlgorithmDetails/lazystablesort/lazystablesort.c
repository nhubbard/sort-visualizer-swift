#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

void swap(int arr[], int a, int b) {
  int t = arr[a];
  arr[a] = arr[b];
  arr[b] = t;
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

void multiSwap(int arr[], int a, int b, int count);
void rotate(int arr[], int pos, int lenA, int lenB);
int binSearch(int arr[], int pos, int len, int keyPos, int isLeft);
void mergeWithoutBuffer(int arr[], int pos, int len1, int len2);

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
  if (len1 < len2) {
    while (len1 != 0) {
      int loc = binSearch(arr, pos + len1, len2, pos, 1);
      if (loc != 0) { rotate(arr, pos, len1, loc); pos += loc; len2 -= loc; }
      if (len2 == 0) break;
      do { pos++; len1--; } while (len1 != 0 && arr[pos] <= arr[pos + len1]);
    }
  } else {
    while (len2 != 0) {
      int loc = binSearch(arr, pos, len1, pos + len1 + len2 - 1, 0);
      if (loc != len1) { rotate(arr, pos + loc, len1 - loc, len2); len1 = loc; }
      if (len1 == 0) break;
      do { len2--; } while (len2 != 0 && arr[pos + len1 - 1] <= arr[pos + len1 + len2 - 1]);
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
