#include <algorithm>
#include <cstdio>
#include <vector>

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

int merge(int arr[], std::vector<int>& scratch, int n, int index, int mergeSize) {
  int mid = index + mergeSize / 2;
  int end = std::min(n, index + mergeSize);
  if (mid >= end) return index;
  int left = index, right = mid, out = index;
  while (left < mid && right < end)
    scratch[out++] = arr[left] <= arr[right] ? arr[left++] : arr[right++];
  while (left < mid) scratch[out++] = arr[left++];
  while (right < end) scratch[out++] = arr[right++];
  return -1;
}

void sort(int arr[], int n) {
  if (n < 2) return;
  std::vector<int> scratch(arr, arr + n);
  int mergeSize = 2;
  while (mergeSize <= n) {
    int copyLength = n;
    for (int index = 0; index < n; index += mergeSize) {
      int stop = merge(arr, scratch, n, index, mergeSize);
      if (stop >= 0) copyLength = stop;
    }
    for (int j = 0; j < copyLength; j++) arr[j] = scratch[j];
    mergeSize *= 2;
  }
  if (mergeSize / 2 != n) {
    int stop = merge(arr, scratch, n, 0, mergeSize);
    int copyLength = stop < 0 ? n : stop;
    for (int j = 0; j < copyLength; j++) arr[j] = scratch[j];
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
