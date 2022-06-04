#include <cstdio>

int items[10] = {35, 95, 74, 71, 72, 30, 96, 53, 9, 0};

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

void merge(int *array, int l, int m, int r) {
  int i, j, k, nl, nr;
  nl = m - l + 1;
  nr = r - m;
  int larr[nl], rarr[nr];
  for (i = 0; i < nl; i++)
    larr[i] = array[l + i];
  for (j = 0; j < nr; j++)
    rarr[j] = array[m + 1 + j];
  i = 0;
  j = 0;
  k = l;
  while (i < nl && j < nr) {
    if (larr[i] <= rarr[j]) {
      array[k] = larr[i];
      i++;
    } else {
      array[k] = rarr[j];
      j++;
    }
    k++;
  }
  while (i < nl) {
    array[k] = larr[i];
    i++;
    k++;
  }
  while (j < nr) {
    array[k] = rarr[j];
    j++;
    k++;
  }
}

void mergeSort(int *array, int l, int r) {
  int m;
  if (l < r) {
    int m = l + (r - l) / 2;
    mergeSort(array, l, m);
    mergeSort(array, m + 1, r);
    merge(array, l, m, r);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(items) / sizeof(items[0]);
  mergeSort(items, 0, size);
  printList(items, size);
  return 0;
}
