#include <stdio.h>
#include <stdlib.h>

int array[7] = {0, 39, 21, 62, 91, 14, 23};

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

int isSortedRange(int arr[], int start, int end) {
  for (int i = start; i < end - 1; i++) {
    if (arr[i] > arr[i + 1]) {
      return 0;
    }
  }
  return 1;
}

void sortRange(int arr[], int start, int end) {
  if (start >= end - 1) {
    return;
  }
  int mid = (start + end) / 2;
  sortRange(arr, start, mid);
  sortRange(arr, mid, end);

  int len = end - start;
  int saved[len];
  for (int i = 0; i < len; i++) {
    saved[i] = arr[start + i];
  }

  int highCount = end - mid;

  while (!isSortedRange(arr, start, end)) {
    int candidates[len];
    for (int i = 0; i < len; i++) {
      candidates[i] = i;
    }
    for (int i = len - 1; i > 0; i--) {
      int j = rand() % (i + 1);
      int t = candidates[i];
      candidates[i] = candidates[j];
      candidates[j] = t;
    }
    int isHigh[len];
    for (int i = 0; i < len; i++) {
      isHigh[i] = 0;
    }
    for (int i = 0; i < highCount; i++) {
      isHigh[candidates[i]] = 1;
    }

    int low = 0;
    int high = mid - start;
    for (int offset = 0; offset < len; offset++) {
      if (isHigh[offset]) {
        arr[start + offset] = saved[high];
        high++;
      } else {
        arr[start + offset] = saved[low];
        low++;
      }
    }
  }
}

void sort(int arr[], int n) { sortRange(arr, 0, n); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
