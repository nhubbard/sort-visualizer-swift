#include <stdio.h>
#include <stdlib.h>

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

void merge(int arr[], int tmp[], int length, int residue, int modulus);

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

void sort(int arr[], int length) {
  int *tmp = malloc(sizeof(int) * length);
  merge(arr, tmp, length, 0, 1);
  free(tmp);
}

void merge(int arr[], int tmp[], int length, int residue, int modulus) {
  if (residue + modulus >= length) {
    return;
  }
  int low = residue;
  int high = residue + modulus;
  int dmodulus = modulus << 1;

  merge(arr, tmp, length, low, dmodulus);
  merge(arr, tmp, length, high, dmodulus);

  int nxt = residue;
  while (low < length && high < length) {
    if (arr[low] > arr[high] || (arr[low] == arr[high] && low > high)) {
      tmp[nxt] = arr[high];
      high += dmodulus;
    } else {
      tmp[nxt] = arr[low];
      low += dmodulus;
    }
    nxt += modulus;
  }
  if (low >= length) {
    while (high < length) {
      tmp[nxt] = arr[high];
      nxt += modulus;
      high += dmodulus;
    }
  } else {
    while (low < length) {
      tmp[nxt] = arr[low];
      nxt += modulus;
      low += dmodulus;
    }
  }
  for (int i = residue; i < length; i += modulus) {
    arr[i] = tmp[i];
  }
}



int main(void) {
  int array[16] = {0,  39, 21, 62, 91, 77, 14, 23,
                   90, 69, 51, 81, 68, 83, 32, 56};
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
