#include <stdio.h>
#include <stdlib.h>

int array[30] = {55, 12, 84, 3, 47, 91, 26, 68, 8,  73, 40, 97, 15, 62, 34,
                 79, 21, 88, 5, 51, 66, 29, 44, 12, 78, 33, 91, 6,  58, 12};

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

void insertionSort(int arr[], int left, int right);
void dualPivot(int arr[], int left, int right, int divisor);

void sort(int arr[], int n) {
  if (n > 1) dualPivot(arr, 0, n - 1, 3);
}

void insertionSort(int arr[], int left, int right) {
  for (int i = left + 1; i <= right; i++) {
    int j = i;
    while (j > left && arr[j] < arr[j - 1]) {
      swap(&arr[j], &arr[j - 1]);
      j--;
    }
  }
}

void dualPivot(int arr[], int left, int right, int divisor) {
  int length = right - left;
  if (length < 27) {
    insertionSort(arr, left, right);
    return;
  }
  int third = length / divisor;
  int med1 = left + third, med2 = right - third;
  if (med1 <= left) med1 = left + 1;
  if (med2 >= right) med2 = right - 1;
  if (arr[med1] < arr[med2]) {
    swap(&arr[med1], &arr[left]);
    swap(&arr[med2], &arr[right]);
  } else {
    swap(&arr[med1], &arr[right]);
    swap(&arr[med2], &arr[left]);
  }
  int pivot1 = arr[left], pivot2 = arr[right];
  int less = left + 1, great = right - 1;
  for (int k = less; k <= great; k++) {
    if (arr[k] < pivot1) {
      swap(&arr[k], &arr[less++]);
    } else if (arr[k] > pivot2) {
      while (k < great && arr[great] > pivot2) great--;
      swap(&arr[k], &arr[great--]);
      if (arr[k] < pivot1) swap(&arr[k], &arr[less++]);
    }
  }
  int dist = great - less;
  if (dist < 13) divisor++;
  swap(&arr[less - 1], &arr[left]);
  swap(&arr[great + 1], &arr[right]);
  dualPivot(arr, left, less - 2, divisor);
  dualPivot(arr, great + 2, right, divisor);
  if (dist > length - 13 && pivot1 != pivot2) {
    for (int k = less; k <= great; k++) {
      if (arr[k] == pivot1) swap(&arr[k], &arr[less++]);
      else if (arr[k] == pivot2) {
        swap(&arr[k], &arr[great--]);
        if (arr[k] == pivot1) swap(&arr[k], &arr[less++]);
      }
    }
  }
  if (pivot1 < pivot2) dualPivot(arr, less, great, divisor);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
