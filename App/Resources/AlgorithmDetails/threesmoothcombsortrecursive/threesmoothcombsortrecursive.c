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

void powerOfThree(int arr[], int pos, int gap, int end);
void recursiveComb(int arr[], int pos, int gap, int end);

void sort(int arr[], int n) {
  if (n > 1) {
    recursiveComb(arr, 0, 1, n);
  }
}

void powerOfThree(int arr[], int pos, int gap, int end) {
  if (pos + gap > end) {
    return;
  }

  powerOfThree(arr, pos, gap * 3, end);
  powerOfThree(arr, pos + gap, gap * 3, end);
  powerOfThree(arr, pos + 2 * gap, gap * 3, end);

  for (int i = pos; i + gap < end; i += gap) {
    if (arr[i] > arr[i + gap]) {
      int t = arr[i];
      arr[i] = arr[i + gap];
      arr[i + gap] = t;
    }
  }
}

void recursiveComb(int arr[], int pos, int gap, int end) {
  if (pos + gap > end) {
    return;
  }

  recursiveComb(arr, pos, gap * 2, end);
  recursiveComb(arr, pos + gap, gap * 2, end);

  powerOfThree(arr, pos, gap, end);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
