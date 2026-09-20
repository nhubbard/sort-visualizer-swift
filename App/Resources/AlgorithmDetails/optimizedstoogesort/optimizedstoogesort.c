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

void forward(int arr[], int left, int right);
void backward(int arr[], int left, int right);
void exchange(int arr[], int length);

void sort(int arr[], int n) {
  exchange(arr, n);
}

void forward(int arr[], int left, int right) {
  while (left < right) {
    int index = right;
    while (left < index) {
      if (arr[left] > arr[index]) {
        swap(&arr[left], &arr[index]);
      }
      left++;
      index--;
    }
    left = 0;
    right--;
  }
}

void backward(int arr[], int left, int right) {
  int length = right;
  while (left < right) {
    int index = left;
    while (index < right) {
      if (arr[index] > arr[right]) {
        swap(&arr[index], &arr[right]);
      }
      index++;
      right--;
    }
    left++;
    right = length;
  }
}

void exchange(int arr[], int length) {
  int left = 0;
  int right = length - 1;
  while (left < right) {
    if (arr[left] > arr[right]) {
      swap(&arr[left], &arr[right]);
    }
    left++;
    right--;
  }

  forward(arr, 0, length - 2);
  backward(arr, 1, length - 1);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
