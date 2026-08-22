#include <cstdio>
#include <utility>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

int idx(int p, int n) { return n - p; }

void siftDown(int arr[], int root, int dist, int n) {
  while (root <= dist / 2) {
    int leaf = 2 * root;
    if (leaf < dist && arr[idx(leaf, n)] > arr[idx(leaf + 1, n)]) {
      leaf++;
    }
    if (arr[idx(root, n)] > arr[idx(leaf, n)]) {
      std::swap(arr[idx(root, n)], arr[idx(leaf, n)]);
      root = leaf;
    } else {
      break;
    }
  }
}

void sort(int arr[], int n) {
  int i = n / 2;
  while (i >= 1) {
    siftDown(arr, i, n, n);
    i--;
  }

  i = n;
  while (i > 1) {
    std::swap(arr[idx(1, n)], arr[idx(i, n)]);
    siftDown(arr, 1, i - 1, n);
    i--;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
