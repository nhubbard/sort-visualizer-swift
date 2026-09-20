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

void mergeTo(int arr[], int subList[], int a, int m, int b);

void sort(int arr[], int n) {
  if (n < 2)
    return;

  int *subList = malloc(n * sizeof(int));

  int j = n;
  int k = j;
  while (j > 0) {
    subList[0] = arr[0];
    k--;

    int i = 0;
    int p = 0;
    for (int m = 1; m < j; m++) {
      if (arr[m] >= subList[i]) {
        i++;
        subList[i] = arr[m];
        k--;
      } else {
        arr[p] = arr[m];
        p++;
      }
    }

    mergeTo(arr, subList, k, j, n);
    j = k;
  }

  free(subList);
}

void mergeTo(int arr[], int subList[], int a, int m, int b) {
  int i = 0;
  int s = m - a;
  while (i < s && m < b) {
    if (subList[i] < arr[m]) {
      arr[a] = subList[i];
      a++;
      i++;
    } else {
      arr[a] = arr[m];
      a++;
      m++;
    }
  }
  while (i < s) {
    arr[a] = subList[i];
    a++;
    i++;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
