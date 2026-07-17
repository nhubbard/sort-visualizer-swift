#include <cstdio>

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

void gappedInsertionSort(int arr[], int a, int b, int gap) {
  for (int i = a + gap; i < b; i += gap) {
    int key = arr[i];
    int j = i - gap;
    while (j >= a && key < arr[j]) {
      arr[j + gap] = arr[j];
      j -= gap;
    }
    arr[j + gap] = key;
  }
}

void recursiveShellSort(int arr[], int start, int end, int g) {
  if (start + g <= end) {
    recursiveShellSort(arr, start, end, 3 * g);
    recursiveShellSort(arr, start + g, end, 3 * g);
    recursiveShellSort(arr, start + (2 * g), end, 3 * g);
    gappedInsertionSort(arr, start, end, g);
  }
}

void sort(int arr[], int length) { recursiveShellSort(arr, 0, length, 1); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
