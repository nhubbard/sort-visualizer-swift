#include <stdio.h>

void multiSwap(int arr[], int pos, int to) {
  if (to - pos > 0) {
    for (int i = pos; i < to; i++) {
      int tmp = arr[i];
      arr[i] = arr[i + 1];
      arr[i + 1] = tmp;
    }
  } else {
    for (int i = pos; i > to; i--) {
      int tmp = arr[i];
      arr[i] = arr[i - 1];
      arr[i - 1] = tmp;
    }
  }
}

void weaveInsert(int arr[], int start, int end) {
  for (int j = start; j < end; j++) {
    int pos = j;
    while (pos > start && arr[pos] <= arr[pos - 1]) {
      int tmp = arr[pos];
      arr[pos] = arr[pos - 1];
      arr[pos - 1] = tmp;
      pos--;
    }
  }
}

void weaveMerge(int arr[], int min, int max, int mid) {
  int target = mid - min;
  for (int i = 1; i <= target; i++) {
    multiSwap(arr, mid + i, min + (i * 2) - 1);
  }
  weaveInsert(arr, min, max + 1);
}

void weaveMergeSort(int arr[], int min, int max) {
  if (max - min == 0) {
    return;
  } else if (max - min == 1) {
    if (arr[min] > arr[max]) {
      int tmp = arr[min];
      arr[min] = arr[max];
      arr[max] = tmp;
    }
  } else {
    int mid = (min + max) / 2;
    weaveMergeSort(arr, min, mid);
    weaveMergeSort(arr, mid + 1, max);
    weaveMerge(arr, min, max, mid);
  }
}

void sort(int arr[], int length) {
  if (length > 1) {
    weaveMergeSort(arr, 0, length - 1);
  }
}

void printList(int arr[], int n) {
  for (int i = 0; i < n; i++) {
    if (i == 0) {
      printf("[%d, ", arr[i]);
    } else if (i != n - 1) {
      printf("%d, ", arr[i]);
    } else {
      printf("%d]\n", arr[i]);
    }
  }
}

int main(void) {
  int array[16] = {0,  39, 21, 62, 91, 77, 14, 23,
                   90, 69, 51, 81, 68, 83, 32, 56};
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
