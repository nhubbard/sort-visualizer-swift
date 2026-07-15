#include <cstdio>
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

void sort(int arr[], int n) {
  permutationSort(arr, n, 0);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
