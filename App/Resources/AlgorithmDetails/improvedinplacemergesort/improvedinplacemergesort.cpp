#include <cstdio>

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

static void push(int arr[], int p, int a, int b) {
  if (a == b) {
    return;
  }
  int temp = arr[p];
  arr[p] = arr[a];
  for (int i = a + 1; i < b; i++) {
    arr[i - 1] = arr[i];
  }
  arr[b - 1] = temp;
}

static void merge(int arr[], int a, int m, int b) {
  int i = a, j = m;
  while (i < m && j < b) {
    if (arr[i] > arr[j]) {
      j++;
    } else {
      push(arr, i, m, j);
      i++;
    }
  }
  while (i < m) {
    push(arr, i, m, b);
    i++;
  }
}

static void mergeSort(int arr[], int a, int b) {
  int m = a + (b - a) / 2;
  if (b - a > 2) {
    if (b - a > 3) {
      mergeSort(arr, a, m);
    }
    mergeSort(arr, m, b);
  }
  merge(arr, a, m, b);
}

void sort(int arr[], int n) { mergeSort(arr, 0, n); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}