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

int stableComp(int arr[], int table[], int a, int b) {
  int ta = table[a];
  int tb = table[b];
  if (arr[ta] > arr[tb]) return 1;
  if (arr[ta] == arr[tb]) return table[a] > table[b];
  return 0;
}

void medianOfThree(int arr[], int table[], int a, int b) {
  int m = a + (b - 1 - a) / 2;
  if (stableComp(arr, table, a, m)) swap(&table[a], &table[m]);
  if (stableComp(arr, table, m, b - 1)) {
    swap(&table[m], &table[b - 1]);
    if (stableComp(arr, table, a, m)) return;
  }
  swap(&table[a], &table[m]);
}

int partition(int arr[], int table[], int a, int b, int p) {
  int i = a - 1;
  int j = b;
  while (1) {
    do {
      i++;
    } while (i < j && !stableComp(arr, table, i, p));
    do {
      j--;
    } while (j >= i && stableComp(arr, table, j, p));
    if (i < j) {
      swap(&table[i], &table[j]);
    } else {
      return j;
    }
  }
}

void quickSort(int arr[], int table[], int a, int b) {
  if (b - a < 3) {
    if (b - a == 2 && stableComp(arr, table, a, a + 1)) {
      swap(&table[a], &table[a + 1]);
    }
    return;
  }
  medianOfThree(arr, table, a, b);
  int p = partition(arr, table, a + 1, b, a);
  swap(&table[a], &table[p]);
  quickSort(arr, table, a, p);
  quickSort(arr, table, p + 1, b);
}

void sort(int arr[], int n) {
  int *table = malloc(n * sizeof(int));
  for (int i = 0; i < n; i++) table[i] = i;
  quickSort(arr, table, 0, n);
  for (int i = 0; i < n; i++) {
    if (table[i] != i) {
      int t = arr[i];
      int j = i;
      int next = table[i];
      do {
        arr[j] = arr[next];
        table[j] = j;
        j = next;
        next = table[next];
      } while (next != i);
      arr[j] = t;
      table[j] = j;
    }
  }
  free(table);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
