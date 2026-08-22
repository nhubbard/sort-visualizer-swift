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

int minFrom(int arr[], int i, int n) {
  int m = arr[i];
  for (int k = i + 1; k < n; k++) {
    if (arr[k] < m) {
      m = arr[k];
    }
  }
  return m;
}

void sort(int arr[], int n) {
  for (int i = 0; i < n; i++) {
    while (arr[i] != minFrom(arr, i, n)) {
      int j = i + rand() % (n - i);
      std::swap(arr[i], arr[j]);
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
