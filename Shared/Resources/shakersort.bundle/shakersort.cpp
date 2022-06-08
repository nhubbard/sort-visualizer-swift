#include <cstdio>
#include <utility>

int items[10] = {35, 95, 74, 71, 72, 30, 96, 53, 9, 0};

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

void shakerSort(int arr[], int n) {
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
  int size = sizeof(items) / sizeof(items[0]);
  shakerSort(items, size);
  printList(items, size);
  return 0;
}