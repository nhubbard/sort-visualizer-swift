#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

void printList(int arr[], int n) {
  for (int i = 0; i < n; i++) {
    if (i == 0) {
      printf("[%d, ", arr[i]);
    } else if (i != n - 1) {
      printf("%d, ", arr[i]);
    } else {
      printf("%d]", arr[i]);
    }
  }
}

void partition(int arr[], int low, int high, int *outJ, int *outG) {
  if (arr[low] > arr[high]) {
    swap(&arr[low], &arr[high]);
  }
  int j = low + 1;
  int g = high - 1;
  int k = low + 1;
  int p = arr[low];
  int q = arr[high];
  while (k <= g) {
    if (arr[k] < p) {
      swap(&arr[k], &arr[j]);
      j++;
    } else if (arr[k] >= q) {
      while (arr[g] > q && k < g) {
        g--;
      }
      swap(&arr[k], &arr[g]);
      g--;
      if (arr[k] < p) {
        swap(&arr[k], &arr[j]);
        j++;
      }
    }
    k++;
  }
  j--;
  g++;
  swap(&arr[low], &arr[j]);
  swap(&arr[high], &arr[g]);
  *outJ = j;
  *outG = g;
}

void sort(int arr[], int low, int high) {
  if (low < high) {
    int j, g;
    partition(arr, low, high, &j, &g);
    sort(arr, low, j - 1);
    sort(arr, j + 1, g - 1);
    sort(arr, g + 1, high);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, 0, size - 1);
  printList(array, size);
  return 0;
}
