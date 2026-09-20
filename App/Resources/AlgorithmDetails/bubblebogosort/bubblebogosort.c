#include <stdio.h>
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
  int array[] = {0, 39, 21, 62, 91, 77, 14, 23};
  int n = (int)(sizeof(array) / sizeof(array[0]));
  sort(array, n);
  printf("[");
  for (int i = 0; i < n; i++)
    printf("%s%d", i ? ", " : "", array[i]);
  printf("]\n");
}
