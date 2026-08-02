#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

void insertionSort(int arr[], int n) {
  for (int i = 1; i < n; i++) {
    int key = arr[i];
    int j = i - 1;
    while (j >= 0 && arr[j] > key) {
      arr[j + 1] = arr[j];
      j = j - 1;
    }
    arr[j + 1] = key;
  }
}

void sort(int arr[], int n) {
  float shrink = 1.3f;
  int gap = n;
  int sorted = 0;
  int threshold = n / 32;
  if (threshold > 8) {
    threshold = 8;
  }
  while (!sorted) {
    gap = (int)((float)gap / shrink);
    if (gap <= 1) {
      sorted = 1;
      gap = 1;
    }
    for (int i = 0; i < n - gap; i++) {
      if (gap <= threshold) {
        insertionSort(arr, n);
        return;
      }
      int sm = gap + i;
      if (arr[i] > arr[sm]) {
        swap(&arr[i], &arr[sm]);
        sorted = 0;
      }
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
