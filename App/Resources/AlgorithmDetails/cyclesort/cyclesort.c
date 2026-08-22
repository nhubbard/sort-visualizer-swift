#include <stdio.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

void sort(int arr[], int n) { cycleSort(arr, n); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
