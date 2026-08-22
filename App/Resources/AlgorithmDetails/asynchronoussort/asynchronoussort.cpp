#include <cstdio>

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

void sort(int arr[], int n) {
  int ext[n];
  int minValue = arr[0];
  int maxValue = arr[0];
  for (int i = 0; i < n; i++) {
    ext[i] = arr[i];
    if (arr[i] < minValue) {
      minValue = arr[i];
    }
    if (arr[i] > maxValue) {
      maxValue = arr[i];
    }
  }
  maxValue++;

  int cur = minValue;
  int i = 0;
  while (i < n) {
    for (int j = 0; j < n; j++) {
      if (ext[j] <= cur) {
        arr[i] = ext[j];
        ext[j] = maxValue;
        i++;
      }
    }
    cur++;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
