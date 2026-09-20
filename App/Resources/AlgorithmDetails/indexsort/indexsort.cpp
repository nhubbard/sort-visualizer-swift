#include <cstdio>
#include <utility>

int array[16] = {7, 3, 14, 0, 9, 5, 12, 1,
                 15, 4, 10, 2, 13, 6, 11, 8};

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

void sort(int arr[], int n) {
  int minValue = arr[0];
  for (int i = 1; i < n; i++) {
    if (arr[i] < minValue) {
      minValue = arr[i];
    }
  }

  for (int i = 0; i < n; i++) {
    int cmpCount = 0;
    while (arr[i] - minValue != i && cmpCount < n) {
      std::swap(arr[i], arr[arr[i] - minValue]);
      cmpCount++;
    }
    if (cmpCount >= n - 1) {
      break;
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
