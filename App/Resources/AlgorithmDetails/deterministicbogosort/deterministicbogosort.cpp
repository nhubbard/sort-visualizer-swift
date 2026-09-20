#include <cstdio>
#include <utility>

int array[7] = {0, 39, 21, 62, 91, 14, 23};

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

bool isSorted(int arr[], int n);
bool permutationSort(int arr[], int n, int depth);

void sort(int arr[], int n) {
  permutationSort(arr, n, 0);
}

bool isSorted(int arr[], int n) {
  for (int i = 1; i < n; i++) {
    if (arr[i] < arr[i - 1]) {
      return false;
    }
  }
  return true;
}

bool permutationSort(int arr[], int n, int depth) {
  if (depth >= n - 1) {
    return isSorted(arr, n);
  }
  for (int i = n - 1; i > depth; i--) {
    if (permutationSort(arr, n, depth + 1)) {
      return true;
    }
    if ((n - depth) % 2 == 0) {
      std::swap(arr[depth], arr[i]);
    } else {
      std::swap(arr[depth], arr[n - 1]);
    }
  }
  return permutationSort(arr, n, depth + 1);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
