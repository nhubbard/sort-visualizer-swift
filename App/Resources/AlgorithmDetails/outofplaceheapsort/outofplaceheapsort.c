#include <stdio.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
int output[16];

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

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

void siftDown(int arr[], int root, int size) {
  int index = root;
  while (2 * index + 1 < size) {
    int child = 2 * index + 1;
    if (child + 1 < size && arr[child + 1] > arr[child]) {
      child++;
    }
    index = child;
  }
  int rootValue = arr[root];
  while (rootValue > arr[index]) {
    index = (index - 1) / 2;
  }
  while (index != root) {
    swap(&arr[root], &arr[index]);
    index = (index - 1) / 2;
  }
}

void heapify(int arr[], int length) {
  for (int i = (length - 1) / 2; i >= 0; i--) {
    siftDown(arr, i, length);
  }
}

void findNext(int arr[], int size) {
  int hole = 0;
  int left = 1;
  int right = 2;
  while (right < size && !(arr[left] == -1 && arr[right] == -1)) {
    if (arr[left] == -1) {
      swap(&arr[hole], &arr[right]);
      hole = right;
    } else if (arr[right] == -1) {
      swap(&arr[hole], &arr[left]);
      hole = left;
    } else if (arr[right] > arr[left]) {
      swap(&arr[hole], &arr[right]);
      hole = right;
    } else {
      swap(&arr[hole], &arr[left]);
      hole = left;
    }
    left = 2 * hole + 1;
    right = left + 1;
  }
  if (left < size && arr[left] != -1) {
    swap(&arr[hole], &arr[left]);
  }
}

void sort(int arr[], int out[], int size) {
  if (size <= 1) {
    if (size == 1) {
      out[0] = arr[0];
    }
    return;
  }
  heapify(arr, size);
  for (int i = size - 1; i >= 0; i--) {
    out[i] = arr[0];
    arr[0] = -1;
    findNext(arr, size);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, output, size);
  printList(output, size);
  return 0;
}
