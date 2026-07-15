#include <cstdio>
#include <cstdlib>
#include <utility>

int array[7] = {0, 39, 21, 62, 91, 14, 23};

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

void shuffleRange(int arr[], int length) {
  for (int i = length - 1; i > 0; i--) {
    int j = rand() % (i + 1);
    std::swap(arr[i], arr[j]);
  }
}

void sort(int arr[], int length) {
  if (length == 1) {
    return;
  }
  sort(arr, length - 1);
  while (arr[length - 2] > arr[length - 1]) {
    shuffleRange(arr, length);
    sort(arr, length - 1);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
