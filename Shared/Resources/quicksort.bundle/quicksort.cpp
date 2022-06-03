#include <cstdio>
// The common header includes the random numbers
// list, along with the swap and printList functions.
#include "../common.h"

int partition(int arr[], int low, int high) {
  int pivot = arr[high];
  int i = low - 1;
  for (int j = low; j < high; j++) {
    if (arr[j] <= pivot) {
      i++;
      swap(&arr[i], &arr[j]);
    }
  }
  swap(&arr[i + 1], &arr[high]);
  return i + 1;
}

void quickSort(int arr[], int low, int high) {
  if (low < high) {
    int pivot = partition(arr, low, high);
    quickSort(arr, low, pivot - 1);
    quickSort(arr, pivot + 1, high);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(items) / sizeof(items[0]);
  quickSort(items, 0, size);
  printList(items, size);
  return 0;
}
