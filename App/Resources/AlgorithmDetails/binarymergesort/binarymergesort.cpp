#include <cstdio>
#include <utility>
#include <vector>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

const int THRESHOLD = 32;

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

void insertionSort(int arr[], int start, int end) {
  for (int i = start + 1; i < end; i++) {
    int j = i;
    while (j > start && arr[j] < arr[j - 1]) {
      std::swap(arr[j - 1], arr[j]);
      j--;
    }
  }
}

void merge(int arr[], int start, int mid, int end) {
  int low = start;
  int high = mid;
  std::vector<int> merged;
  merged.reserve(end - start);
  while (low < mid && high < end) {
    if (arr[high] < arr[low]) {
      merged.push_back(arr[high++]);
    } else {
      merged.push_back(arr[low++]);
    }
  }
  while (low < mid) {
    merged.push_back(arr[low++]);
  }
  while (high < end) {
    merged.push_back(arr[high++]);
  }
  for (size_t i = 0; i < merged.size(); i++) {
    arr[start + i] = merged[i];
  }
}

void mergeSort(int arr[], int start, int end) {
  if (end - start <= THRESHOLD) {
    insertionSort(arr, start, end);
    return;
  }
  int mid = start + (end - start) / 2;
  mergeSort(arr, start, mid);
  mergeSort(arr, mid, end);
  merge(arr, start, mid, end);
}

void sort(int arr[], int n) {
  if (n < 2)
    return;
  mergeSort(arr, 0, n);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
