#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

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

int binarySearch(int arr[], int item, int start, int end) {
  int lo = start;
  int hi = end;
  while (lo < hi) {
    int mid = lo + (hi - lo) / 2;
    if (item < arr[mid]) {
      hi = mid;
    } else {
      lo = mid + 1;
    }
  }
  return lo;
}

void binaryInsertionSort(int arr[], int start, int end) {
  for (int i = start + 1; i < end; i++) {
    int item = arr[i];
    int pos = binarySearch(arr, item, start, i);
    int j = i;
    while (j > pos) {
      arr[j] = arr[j - 1];
      j--;
    }
    arr[pos] = item;
  }
}

void rebalance(int arr[], int temp[], int counts[], int locations[], int spineSize, int batchEnd) {
  for (int i = 0; i < spineSize; i++) {
    counts[i + 1] = counts[i + 1] + counts[i] + 1;
  }

  int k = 0;
  for (int i = spineSize; i < batchEnd; i++) {
    int gap = locations[k];
    int position = counts[gap];
    temp[position] = arr[i];
    counts[gap] = position + 1;
    k++;
  }

  for (int i = 0; i < spineSize; i++) {
    int position = counts[i];
    temp[position] = arr[i];
    counts[i] = position + 1;
  }

  for (int i = 0; i < batchEnd; i++) {
    arr[i] = temp[i];
  }

  binaryInsertionSort(arr, 0, counts[0] - 1);
  for (int i = 0; i < spineSize - 1; i++) {
    binaryInsertionSort(arr, counts[i], counts[i + 1] - 1);
  }
  binaryInsertionSort(arr, counts[spineSize - 1], counts[spineSize]);

  for (int i = 0; i < spineSize + 2; i++) {
    counts[i] = 0;
  }
}

void librarySort(int arr[], int n) {
  if (n < 2) {
    return;
  }

  int rebalanceFactor = 2;
  int spineSize = 1;
  binaryInsertionSort(arr, 0, spineSize);

  int maxLevel = spineSize;
  while (maxLevel * rebalanceFactor < n) {
    maxLevel *= rebalanceFactor;
  }

  int *temp = calloc(n, sizeof(int));
  int *counts = calloc(maxLevel + 2, sizeof(int));
  int *locations = calloc(n, sizeof(int));

  int i = spineSize;
  int k = 0;
  while (i < n) {
    if (rebalanceFactor * spineSize == i) {
      rebalance(arr, temp, counts, locations, spineSize, i);
      spineSize = i;
      k = 0;
    }
    int gap = binarySearch(arr, arr[i], 0, spineSize);
    counts[gap + 1]++;
    locations[k] = gap;
    k++;
    i++;
  }
  rebalance(arr, temp, counts, locations, spineSize, n);

  free(temp);
  free(counts);
  free(locations);
}

void sort(int arr[], int n) {
  librarySort(arr, n);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
