#include <stdio.h>

int array[8] = {0, 39, 21, 62, 91, 77, 14, 23};

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

static void reverse(int *a, int low, int high);

void sort(int *a, int n) {
  if (n < 2)
    return;
  int ordered = 1;
  for (int i = 1; i < n; i++)
    if (a[i] < a[i - 1]) {
      ordered = 0;
      break;
    }
  if (ordered)
    return;
  for (;;) {
    int pivot = n - 2;
    while (pivot >= 0 && a[pivot] >= a[pivot + 1])
      pivot--;
    if (pivot < 0)
      break;
    int successor = n - 1;
    while (a[successor] <= a[pivot])
      successor--;
    int held = a[pivot];
    a[pivot] = a[successor];
    a[successor] = held;
    reverse(a, pivot + 1, n - 1);
  }
  reverse(a, 0, n - 1);
}

static void reverse(int *a, int low, int high) {
  while (low < high) {
    int held = a[low];
    a[low] = a[high];
    a[high] = held;
    low++;
    high--;
  }
}

int main(void) {
  int n = (int)(sizeof(array) / sizeof(array[0]));
  sort(array, n);
  printList(array, n);
}
