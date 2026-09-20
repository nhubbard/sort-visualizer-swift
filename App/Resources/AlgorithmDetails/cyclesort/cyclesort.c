#include <stdio.h>

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

void cycleSort(int arr[], int n);

void sort(int arr[], int n) {
  cycleSort(arr, n);
}

void cycleSort(int arr[], int n) {
  for (int cycleStart = 0; cycleStart < n - 1; cycleStart++) {
    int item = arr[cycleStart];
    int pos = cycleStart;
    for (int i = cycleStart + 1; i < n; i++) {
      if (arr[i] < item)
        pos++;
    }
    if (pos == cycleStart)
      continue;

    while (item == arr[pos])
      pos++;
    int temp = arr[pos];
    arr[pos] = item;
    item = temp;

    while (pos != cycleStart) {
      pos = cycleStart;
      for (int i = cycleStart + 1; i < n; i++) {
        if (arr[i] < item)
          pos++;
      }
      while (item == arr[pos])
        pos++;
      temp = arr[pos];
      arr[pos] = item;
      item = temp;
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
