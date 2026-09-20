#include <cstdio>
#include <utility>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

void printList(int items[], int size) {
  printf("[");
  if (size > 0) {
    printf("%d", items[0]);
    for (int i = 1; i < size; i++) {
      printf(", %d", items[i]);
    }
  }
  printf("]");
}

void push(int arr[], int low, int high);
void merge(int arr[], int low, int high, int mid);
void mergeSort(int arr[], int low, int high);

void sort(int arr[], int n) {
  if (n >= 2) {
    mergeSort(arr, 0, n - 1);
  }
}

void push(int arr[], int low, int high) {
  for (int i = low; i < high; i++) {
    if (arr[i] > arr[i + 1]) {
      std::swap(arr[i], arr[i + 1]);
    }
  }
}

void merge(int arr[], int low, int high, int mid) {
  int i = low;
  while (i <= mid) {
    if (arr[i] > arr[mid + 1]) {
      std::swap(arr[i], arr[mid + 1]);
      push(arr, mid + 1, high);
    }
    i++;
  }
}

void mergeSort(int arr[], int low, int high) {
  if (high - low == 0) {
    return;
  } else if (high - low == 1) {
    if (arr[low] > arr[high]) {
      std::swap(arr[low], arr[high]);
    }
  } else {
    int mid = (low + high) / 2;
    mergeSort(arr, low, mid);
    mergeSort(arr, mid + 1, high);
    merge(arr, low, high, mid);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
