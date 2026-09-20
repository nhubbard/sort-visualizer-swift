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

void doubleSelectionSort(int arr[], int n);

void sort(int arr[], int n) {
  doubleSelectionSort(arr, n);
}

void doubleSelectionSort(int arr[], int n) {
  if (n <= 1) {
    return;
  }

  int left = 0;
  int right = n - 1;
  int smallest = 0;
  int biggest = 0;

  while (left <= right) {
    for (int i = left; i <= right; i++) {
      if (arr[i] > arr[biggest]) {
        biggest = i;
      }
      if (arr[i] < arr[smallest]) {
        smallest = i;
      }
    }

    if (biggest == left) {
      biggest = smallest;
    }

    int temp = arr[left];
    arr[left] = arr[smallest];
    arr[smallest] = temp;

    temp = arr[right];
    arr[right] = arr[biggest];
    arr[biggest] = temp;

    left++;
    right--;
    smallest = left;
    biggest = right;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
