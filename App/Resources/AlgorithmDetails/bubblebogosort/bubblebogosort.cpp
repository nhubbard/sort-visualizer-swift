#include <cstdio>
#include <cstdlib>
#include <utility>

int array[8] = {0, 39, 21, 62, 91, 77, 14, 23};

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

bool isSorted(int arr[], int n) {
  for (int i = 1; i < n; i++) {
    if (arr[i] < arr[i - 1]) {
      return false;
    }
  }
  return true;
}

void sort(int arr[], int n) {
  while (!isSorted(arr, n)) {
    int index = rand() % (n - 1);
    if (arr[index] > arr[index + 1]) {
      std::swap(arr[index], arr[index + 1]);
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
