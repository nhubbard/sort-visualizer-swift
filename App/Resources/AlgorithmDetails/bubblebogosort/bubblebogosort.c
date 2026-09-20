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
void sort(int *a, int n) {
  if (n < 2)
    return;
  int swapped = 1;
  while (swapped) {
    swapped = 0;
    for (int i = 0; i + 1 < n; i++)
      if (a[i] > a[i + 1]) {
        int held = a[i];
        a[i] = a[i + 1];
        a[i + 1] = held;
        swapped = 1;
      }
  }
}
int main(void) {
  int n = (int)(sizeof(array) / sizeof(array[0]));
  sort(array, n);
  printList(array, n);
}
