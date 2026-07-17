#include <cstdio>
#include <utility>

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

void maxHeapify(int arr[], int i, int heapSize) {
  int left = 3 * i + 1;
  int mid = 3 * i + 2;
  int right = 3 * i + 3;
  int largest = i;
  if (left <= heapSize && arr[left] > arr[largest]) {
    largest = left;
  }
  if (right <= heapSize && arr[right] > arr[largest]) {
    largest = right;
  }
  if (mid <= heapSize && arr[mid] > arr[largest]) {
    largest = mid;
  }
  if (largest != i) {
    std::swap(arr[i], arr[largest]);
    maxHeapify(arr, largest, heapSize);
  }
}

void sort(int arr[], int n) {
  int heapSize = n - 1;

  for (int i = n - 1; i >= 0; i--) {
    maxHeapify(arr, i, heapSize);
  }

  for (int i = n - 1; i >= 0; i--) {
    std::swap(arr[0], arr[i]);
    heapSize--;
    maxHeapify(arr, 0, heapSize);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
