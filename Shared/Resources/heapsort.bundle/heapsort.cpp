#include <cstdio>
#include <utility>

void heapify(int arr[], int n, int i) {
  int largest = i;
  int left = 2 * i + 1;
  int right = 2 * i + 2;
  if (left < n && arr[left] > arr[largest]) {
    largest = left;
  }
  if (right < n && arr[right] > arr[largest]) {
    largest = right;
  }
  if (largest != i) {
    std::swap(arr[i], arr[largest]);
    heapify(arr, n, largest);
  }
}

void heapSort(int arr[], int n) {
  for (int i = n / 2 - 1; i >= 0; i--) {
    heapify(arr, n, i);
  }
  for (int i = n - 1; i >= 0; i--) {
    std::swap(arr[0], arr[i]);
    heapify(arr, i, 0);
  }
}

int main(int argc, char* argv[]) {
  int items[8] = {1, 5, 2, 3, 7, 4, 8, 9};
  int size = sizeof(items) / sizeof(items[0]);
  heapSort(items, size);
  for (int item : items) {
    printf("%d", item);
  }
  return 0;
}