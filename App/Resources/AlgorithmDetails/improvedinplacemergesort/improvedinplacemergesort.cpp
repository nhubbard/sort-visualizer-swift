#include <cstdio>

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

static void push(int arr[], int p, int a, int b);
static void merge(int arr[], int a, int m, int b);
static void mergeSort(int arr[], int a, int b);

void sort(int arr[], int n) {
  mergeSort(arr, 0, n);
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

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
