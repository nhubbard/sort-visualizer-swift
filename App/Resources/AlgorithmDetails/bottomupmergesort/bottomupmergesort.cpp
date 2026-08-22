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

void merge(int arr[], int low, int mid, int high) {
  std::vector<int> left(arr + low, arr + mid);
  std::vector<int> right(arr + mid, arr + high);
  size_t i = 0, j = 0;
  int k = low;
  while (i < left.size() && j < right.size()) {
    if (left[i] <= right[j]) {
      arr[k++] = left[i++];
    } else {
      arr[k++] = right[j++];
    }
  }
  while (i < left.size()) {
    arr[k++] = left[i++];
  }
  while (j < right.size()) {
    arr[k++] = right[j++];
  }
}

void sort(int arr[], int n) {
  for (int width = 1; width < n; width *= 2) {
    for (int low = 0; low < n; low += 2 * width) {
      int mid = std::min(low + width, n);
      int high = std::min(low + 2 * width, n);
      if (mid < high) {
        merge(arr, low, mid, high);
      }
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
