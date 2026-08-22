#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

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
  printf("\n");
}

int minRunLength(int n) {
  int r = 0;
  while (n >= 64) {
    r |= n & 1;
    n >>= 1;
  }
  return n + r;
}

void cocktailShakerSort(int arr[], int start, int end) {
  int length = end - start;
  if (length <= 1) {
    return;
  }
  int i = 0;
  while (i < length / 2) {
    int isSorted = 1;
    int j = i;
    while (j < length - i - 1) {
      if (arr[start + j] > arr[start + j + 1]) {
        swap(&arr[start + j], &arr[start + j + 1]);
        isSorted = 0;
      }
      j++;
    }
    j = length - i - 1;
    while (j > i) {
      if (arr[start + j - 1] > arr[start + j]) {
        swap(&arr[start + j - 1], &arr[start + j]);
        isSorted = 0;
      }
      j--;
    }
    if (isSorted) {
      break;
    }
    i++;
  }
}

void merge(int arr[], int start, int mid, int end) {
  int leftLength = mid - start;
  int rightLength = end - mid;
  int *left = malloc(leftLength * sizeof(int));
  int *right = malloc(rightLength * sizeof(int));
  for (int x = 0; x < leftLength; x++) {
    left[x] = arr[start + x];
  }
  for (int x = 0; x < rightLength; x++) {
    right[x] = arr[mid + x];
  }
  int i = 0, j = 0, k = start;
  while (i < leftLength && j < rightLength) {
    if (left[i] <= right[j]) {
      arr[k] = left[i];
      i++;
    } else {
      arr[k] = right[j];
      j++;
    }
    k++;
  }
  while (i < leftLength) {
    arr[k] = left[i];
    i++;
    k++;
  }
  while (j < rightLength) {
    arr[k] = right[j];
    j++;
    k++;
  }
  free(left);
  free(right);
}

void cocktailMergeSort(int arr[], int n) {
  if (n <= 1) {
    return;
  }
  int minRun = minRunLength(n);
  if (n == minRun) {
    cocktailShakerSort(arr, 0, n);
    return;
  }
  int i = 0;
  while (i <= n - minRun) {
    cocktailShakerSort(arr, i, i + minRun);
    i += minRun;
  }
  if (i < n) {
    cocktailShakerSort(arr, i, n);
  }
  int width = minRun;
  while (width < n) {
    i = 0;
    while (i < n) {
      int mid = i + width < n ? i + width : n;
      int end = i + 2 * width < n ? i + 2 * width : n;
      if (mid < end) {
        merge(arr, i, mid, end);
      }
      i += 2 * width;
    }
    width *= 2;
  }
}

void sort(int arr[], int n) { cocktailMergeSort(arr, n); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
