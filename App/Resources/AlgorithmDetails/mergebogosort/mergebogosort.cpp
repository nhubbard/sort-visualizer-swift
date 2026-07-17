#include <algorithm>
#include <cstdio>
#include <random>

int array[7] = {0, 39, 21, 62, 91, 14, 23};
std::mt19937 rng(std::random_device{}());

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

bool isSortedRange(int arr[], int start, int end) {
  for (int i = start; i < end - 1; i++) {
    if (arr[i] > arr[i + 1]) {
      return false;
    }
  }
  return true;
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

  while (!isSortedRange(arr, start, end)) {
    int slots[len];
    for (int i = 0; i < len; i++) {
      slots[i] = i;
    }
    std::shuffle(slots, slots + len, rng);

    bool isHigh[len];
    for (int i = 0; i < len; i++) {
      isHigh[i] = false;
    }
    int highCount = end - mid;
    for (int i = 0; i < highCount; i++) {
      isHigh[slots[i]] = true;
    }

    int low = 0, high = mid - start;
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
