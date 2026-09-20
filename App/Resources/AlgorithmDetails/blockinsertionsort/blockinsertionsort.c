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

int findRun(int arr[], int a, int b) {
  int i = a + 1;
  if (i == b)
    return i;
  if (arr[i - 1] > arr[i]) {
    i++;
    while (i < b && arr[i - 1] > arr[i])
      i++;
    int lo = a, hi = i - 1;
    while (lo < hi) {
      swap(arr, lo, hi);
      lo++;
      hi--;
    }
  } else {
    i++;
    while (i < b && arr[i - 1] <= arr[i])
      i++;
  }
  return i;
}

void insert1(int arr[], int a, int l) {
  int tmp = arr[l];
  l--;
  while (l >= a && arr[l] > tmp) {
    arr[l + 1] = arr[l];
    l--;
  }
  arr[l + 1] = tmp;
}

void insert2(int arr[], int a, int l, int r) {
  int tmpL = arr[l];
  int tmpR = arr[r];
  l--;
  while (l >= a && arr[l] > tmpR) {
    arr[l + 2] = arr[l];
    l--;
  }
  arr[l + 2] = tmpR;
  while (l >= a && arr[l] > tmpL) {
    arr[l + 1] = arr[l];
    l--;
  }
  arr[l + 1] = tmpL;
}

void sort(int arr[], int n) {
  if (n < 2) return;
  int i = findRun(arr, 0, n);
  while (i < n) {
    int j = findRun(arr, i, n);
    int len = j - i;
    if (len == 1)
      insert1(arr, 0, i);
    else if (len == 2)
      insert2(arr, 0, i, i + 1);
    else
      mergeWithoutBuffer(arr, 0, i, len);
    i = j;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
