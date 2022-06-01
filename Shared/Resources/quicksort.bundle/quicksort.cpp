#include <cstdio>
#include <utility>

int partition(int arr[], int low, int high) {
  int pivot = arr[high];
  int i = (low - 1);
  for (int j = low; j <= high - 1; j++) {
    if (arr[j] <= pivot) {
      i++;
      std::swap(arr[i], arr[j]);
    }
  }
  std::swap(arr[i + 1], arr[high]);
  return (i + 1);
}

void quickSort(int arr[], int low, int high) {
  if (low < high) {
    int pivot = partition(arr, low, high);
    quickSort(arr, low, pivot - 1);
    quickSort(arr, pivot + 1, high);
  }
}

int main(int argc, char *argv[]) {
  int items[8] = {1, 5, 2, 3, 7, 4, 8, 9};
  quickSort(items, 0, sizeof(items) / sizeof(items[0]));
  for (int i = 0; i < sizeof(items) / sizeof(items[0]); i++) {
    printf("%d", items[i]);
  }
  return 0;
}
