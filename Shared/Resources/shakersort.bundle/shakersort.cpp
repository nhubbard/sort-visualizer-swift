#include <cstdio>
#include <utility>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

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

void sort(int arr[], int n) {
  int swapped = 1;
  int start = 0;
  int end = n - 1;
  while (swapped) {
    swapped = 0;
    for (int i = start; i < end; i++) {
      if (arr[i] > arr[i + 1]) {
        std::swap(arr[i], arr[i + 1]);
        swapped = 1;
      }
    }
    if (!swapped) {
      break;
    }
    swapped = 0;
    end--;
    for (int i = end - 1; i >= start; i--) {
      if (arr[i] > arr[i + 1]) {
        std::swap(arr[i], arr[i + 1]);
        swapped = 1;
      }
    }
    start++;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}