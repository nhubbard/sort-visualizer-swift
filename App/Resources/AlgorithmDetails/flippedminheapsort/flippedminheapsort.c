#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

void printList(int items[], int size) {
  for (int i = 0; i < size; i++) {
    if (i == 0) {
      printf("[%d, ", items[i]);
    } else if (i != size - 1) {
      printf("%d, ", items[i]);
    } else {
      printf("%d]", items[i]);
    }
  }
}

int idxOf(int n, int p) { return n - p; }

void siftDown(int arr[], int n, int root, int dist) {
  while (root <= dist / 2) {
    int leaf = 2 * root;
    if (leaf < dist && arr[idxOf(n, leaf)] > arr[idxOf(n, leaf + 1)]) {
      leaf += 1;
    }
    if (arr[idxOf(n, root)] > arr[idxOf(n, leaf)]) {
      int t = arr[idxOf(n, root)];
      arr[idxOf(n, root)] = arr[idxOf(n, leaf)];
      arr[idxOf(n, leaf)] = t;
      root = leaf;
    } else {
      break;
    }
  }
}

void sort(int arr[], int n) {
  int i = n / 2;
  while (i >= 1) {
    siftDown(arr, n, i, n);
    i -= 1;
  }

  i = n;
  while (i > 1) {
    int t = arr[idxOf(n, 1)];
    arr[idxOf(n, 1)] = arr[idxOf(n, i)];
    arr[idxOf(n, i)] = t;
    siftDown(arr, n, 1, i - 1);
    i -= 1;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
