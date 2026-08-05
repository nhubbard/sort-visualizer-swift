#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

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

void reverseRun(int arr[], int lo, int hi) {
  while (lo < hi) {
    swap(&arr[lo], &arr[hi]);
    lo++;
    hi--;
  }
}

/* Finds the maximal run starting at indexIn (every adjacent step in the same
 * direction), reversing it in place if that direction was descending.
 * Returns the index where the next run starts, or -1 if this was the last
 * run. */
int identifyRun(int arr[], int indexIn, int n) {
  if (indexIn >= n - 1) {
    return -1;
  }
  int startIndex = indexIn;
  int index = indexIn;
  int ascending = arr[index] <= arr[index + 1];
  index++;
  while (index < n - 1) {
    int stepAscending = arr[index] <= arr[index + 1];
    if (stepAscending != ascending) {
      break;
    }
    index++;
  }
  if (!ascending) {
    reverseRun(arr, startIndex, index);
  }
  return index >= n - 1 ? -1 : index + 1;
}

/* Merges arr[start..mid) with arr[mid..end) by copying the left run into a
 * scratch buffer and merging forward from the low end. */
void mergeUp(int arr[], int start, int mid, int end, int *buffer) {
  for (int i = 0; i < mid - start; i++) {
    buffer[i] = arr[start + i];
  }
  int bufferPointer = 0;
  int left = start;
  int right = mid;
  while (left < right && right < end) {
    if (buffer[bufferPointer] <= arr[right]) {
      arr[left] = buffer[bufferPointer];
      bufferPointer++;
    } else {
      arr[left] = arr[right];
      right++;
    }
    left++;
  }
  while (left < right) {
    arr[left] = buffer[bufferPointer];
    bufferPointer++;
    left++;
  }
}

/* Merges arr[start..mid) with arr[mid..end) by copying the right run into a
 * scratch buffer and merging backward from the high end. */
void mergeDown(int arr[], int start, int mid, int end, int *buffer) {
  for (int i = 0; i < end - mid; i++) {
    buffer[i] = arr[mid + i];
  }
  int bufferPointer = end - mid - 1;
  int left = mid - 1;
  int right = end - 1;
  while (right > left && left >= start) {
    if (buffer[bufferPointer] >= arr[left]) {
      arr[right] = buffer[bufferPointer];
      bufferPointer--;
    } else {
      arr[right] = arr[left];
      left--;
    }
    right--;
  }
  while (right > left) {
    arr[right] = buffer[bufferPointer];
    bufferPointer--;
    right--;
  }
}

/* Picks whichever of mergeUp/mergeDown needs the smaller scratch copy. */
void mergeRuns(int arr[], int leftStart, int rightStart, int end, int *buffer) {
  if (end - rightStart < rightStart - leftStart) {
    mergeDown(arr, leftStart, rightStart, end, buffer);
  } else {
    mergeUp(arr, leftStart, rightStart, end, buffer);
  }
}

void sort(int arr[], int n) {
  if (n < 2) {
    return;
  }

  int *runs = malloc((size_t)n * sizeof(int));
  int runCount = 0;
  int lastRun = 0;
  while (lastRun != -1) {
    runs[runCount++] = lastRun;
    lastRun = identifyRun(arr, lastRun, n);
  }

  int *buffer = malloc((size_t)n * sizeof(int));
  while (runCount > 1) {
    int i = 0;
    while (i < runCount - 1) {
      int end = (i + 2 >= runCount) ? n : runs[i + 2];
      mergeRuns(arr, runs[i], runs[i + 1], end, buffer);
      i += 2;
    }

    int newCount = 0;
    for (int j = 0; j < runCount; j += 2) {
      runs[newCount++] = runs[j];
    }
    runCount = newCount;
  }

  free(buffer);
  free(runs);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
