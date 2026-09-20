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

void siftDown(int arr[], int root, int size) {
  while (true) {
    int largest = root;
    int left = 2 * root + 1;
    int right = left + 1;
    if (left < size && arr[largest] < arr[left]) largest = left;
    if (right < size && arr[largest] < arr[right]) largest = right;
    if (largest == root) break;
    std::swap(arr[root], arr[largest]);
    root = largest;
  }
}

void sort(int arr[], int n) {
  for (int i = n / 2 - 1; i >= 0; i--) {
    siftDown(arr, i, n);
  }
  for (int i = n - 1; i > 0; i--) {
    std::swap(arr[0], arr[i]);
    siftDown(arr, 0, i);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}