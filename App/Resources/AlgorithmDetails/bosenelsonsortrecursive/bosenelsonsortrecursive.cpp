#include <cstdio>
#include <utility>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

void compSwap(int arr[], int start, int end) {
  if (arr[start] > arr[end]) {
    std::swap(arr[start], arr[end]);
  }
}

void merge(int arr[], int start1, int len1, int start2, int len2) {
  if (len1 == 1 && len2 == 1) {
    compSwap(arr, start1, start2);
  } else if (len1 == 1 && len2 == 2) {
    compSwap(arr, start1, start2 + 1);
    compSwap(arr, start1, start2);
  } else if (len1 == 2 && len2 == 1) {
    compSwap(arr, start1, start2);
    compSwap(arr, start1 + 1, start2);
  } else {
    int mid1 = len1 / 2;
    int mid2 = (len1 % 2 == 1) ? len2 / 2 : (len2 + 1) / 2;
    merge(arr, start1, mid1, start2, mid2);
    merge(arr, start1 + mid1, len1 - mid1, start2 + mid2, len2 - mid2);
    merge(arr, start1 + mid1, len1 - mid1, start2, mid2);
  }
}

void boseNelson(int arr[], int start, int length) {
  if (length > 1) {
    int mid = length / 2;
    boseNelson(arr, start, mid);
    boseNelson(arr, start + mid, length - mid);
    merge(arr, start, mid, start + mid, length - mid);
  }
}

void sort(int arr[], int n) { boseNelson(arr, 0, n); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}