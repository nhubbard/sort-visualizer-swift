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

void slowSort(int arr[], int i, int j);

void sort(int arr[], int n) {
  slowSort(arr, 0, n - 1);
}

void slowSort(int arr[], int i, int j) {
  if (i >= j) {
    return;
  }
  int m = i + (j - i) / 2;
  slowSort(arr, i, m);
  slowSort(arr, m + 1, j);
  if (arr[m] > arr[j]) {
    std::swap(arr[m], arr[j]);
  }
  slowSort(arr, i, j - 1);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
