#include <cstdio>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

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

void merge(int *array, int l, int m, int r);

void sort(int *array, int l, int r) {
  int m;
  if (l < r) {
    int m = l + (r - l) / 2;
    sort(array, l, m);
    sort(array, m + 1, r);
    merge(array, l, m, r);
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

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, 0, size - 1);
  printList(array, size);
  return 0;
}
