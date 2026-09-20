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

int idx(int p, int n);
void siftDown(int arr[], int root, int dist, int n);

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

int idx(int p, int n) {
  return n - p;
}

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

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
