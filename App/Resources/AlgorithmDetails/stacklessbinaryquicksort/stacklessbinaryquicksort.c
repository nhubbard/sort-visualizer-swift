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

int mostSignificantBit(int value) {
  if (value == 0)
    return -1;
  int bit = 0;
  while ((value >> (bit + 1)) != 0)
    bit++;
  return bit;
}

int getBit(int value, int bit) { return (value >> bit) & 1; }

int partition(int arr[], int lo, int hi, int bit) {
  int i = lo - 1;
  int j = hi;
  while (1) {
    i++;
    while (i < j && !getBit(arr[i], bit))
      i++;
    j--;
    while (j > i && getBit(arr[j], bit))
      j--;
    if (i < j) {
      swap(&arr[i], &arr[j]);
    } else {
      return i;
    }
  }
}

void sort(int arr[], int n) {
  if (n <= 1)
    return;

  int maxValue = arr[0];
  for (int i = 1; i < n; i++) {
    if (arr[i] > maxValue)
      maxValue = arr[i];
  }

  int q = mostSignificantBit(maxValue);
  if (q < 0)
    return;

  int m = 0;
  int i = 0;
  int b = n;

  while (i < n) {
    int p = (b - i < 1) ? i : partition(arr, i, b, q);

    if (q == 0) {
      m += 2;
      while (!getBit(m, q + 1))
        q++;
      i = b;
      while (b < n && (arr[b] >> (q + 1)) == (m >> (q + 1)))
        b++;
    } else {
      b = p;
      q--;
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}