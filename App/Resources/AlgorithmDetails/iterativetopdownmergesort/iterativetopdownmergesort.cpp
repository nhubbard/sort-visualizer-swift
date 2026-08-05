#include <cstdio>
#include <vector>

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
  int subarrayCount = 1;
  while (subarrayCount < n) {
    subarrayCount *= 2;
  }

  while (subarrayCount > 1) {
    for (int i = 0; i < subarrayCount; i += 2) {
      int low = n * i / subarrayCount;
      int mid = n * (i + 1) / subarrayCount;
      int high = n * (i + 2) / subarrayCount;
      merge(arr, low, mid, high);
    }
    subarrayCount /= 2;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}