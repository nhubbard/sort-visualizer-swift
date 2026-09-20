#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

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

void sort(int arr[], int n) {
  int sm;
  float shrink = 1.3f;
  int gap = n;
  int sorted = 0;
  while (!sorted) {
    gap = (int)((float)gap / shrink);
    if (gap <= 1) {
      sorted = 1;
      gap = 1;
    }
    for (int i = 0; i < n - gap; i++) {
      sm = gap + i;
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
