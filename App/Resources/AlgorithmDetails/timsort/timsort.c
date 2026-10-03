#include <stdio.h>
#include <stdlib.h>

typedef struct {
  int base;
  int length;
} Run;

int minRunLength(int value) {
  int n = value, remainder = 0;
  while (n >= 32) {
    remainder |= n & 1;
    n >>= 1;
  }
  return n + remainder;
}

int countRun(int values[], int n, int start) {
  int end = start + 1;
  if (end == n)
    return 1;
  int descending = values[end] < values[start];
  end++;
  if (descending) {
    while (end < n && values[end] < values[end - 1])
      end++;
    for (int left = start, right = end - 1; left < right; left++, right--) {
      int value = values[left];
      values[left] = values[right];
      values[right] = value;
    }
  } else {
    while (end < n && values[end] >= values[end - 1])
      end++;
  }
  return end - start;
}

void binaryInsertion(int values[], int start, int end, int sortedEnd) {
  for (int index = sortedEnd; index < end; index++) {
    int pivot = values[index];
    int low = start, high = index;
    while (low < high) {
      int middle = low + (high - low) / 2;
      if (values[middle] <= pivot)
        low = middle + 1;
      else
        high = middle;
    }
    for (int shift = index; shift > low; shift--)
      values[shift] = values[shift - 1];
    values[low] = pivot;
  }
}

void merge(int values[], Run runs[], int *stackSize, int index) {
  int start = runs[index].base;
  int leftLength = runs[index].length;
  int rightStart = runs[index + 1].base;
  int rightLength = runs[index + 1].length;
  int *left = (int *)malloc((size_t)leftLength * sizeof(int));
  int *right = (int *)malloc((size_t)rightLength * sizeof(int));
  if (left == NULL || right == NULL) {
    free(left);
    free(right);
    exit(EXIT_FAILURE);
  }
  for (int i = 0; i < leftLength; i++)
    left[i] = values[start + i];
  for (int j = 0; j < rightLength; j++)
    right[j] = values[rightStart + j];
  int i = 0, j = 0, destination = start;
  while (i < leftLength && j < rightLength) {
    if (left[i] <= right[j])
      values[destination++] = left[i++];
    else
      values[destination++] = right[j++];
  }
  while (i < leftLength)
    values[destination++] = left[i++];
  while (j < rightLength)
    values[destination++] = right[j++];
  free(left);
  free(right);
  runs[index].length = leftLength + rightLength;
  for (int position = index + 1; position + 1 < *stackSize; position++) {
    runs[position] = runs[position + 1];
  }
  (*stackSize)--;
}

void sort(int values[], int n) {
  if (n < 2)
    return;
  int minimum = minRunLength(n);
  Run runs[128];
  int stackSize = 0, cursor = 0;
  while (cursor < n) {
    int length = countRun(values, n, cursor);
    int forced = minimum < n - cursor ? minimum : n - cursor;
    if (length < forced) {
      binaryInsertion(values, cursor, cursor + forced, cursor + length);
      length = forced;
    }
    runs[stackSize++] = (Run){cursor, length};
    while (stackSize > 1) {
      int index = stackSize - 2;
      if ((index >= 1 && runs[index - 1].length <=
                             runs[index].length + runs[index + 1].length) ||
          (index >= 2 && runs[index - 2].length <=
                             runs[index].length + runs[index - 1].length)) {
        if (runs[index - 1].length < runs[index + 1].length)
          index--;
      } else if (runs[index].length > runs[index + 1].length)
        break;
      merge(values, runs, &stackSize, index);
    }
    cursor += length;
  }
  while (stackSize > 1) {
    int index = stackSize - 2;
    if (index > 0 && runs[index - 1].length < runs[index + 1].length)
      index--;
    merge(values, runs, &stackSize, index);
  }
}

int main(void) {
  int array[] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
  int n = (int)(sizeof(array) / sizeof(array[0]));
  sort(array, n);
  printf("[");
  for (int i = 0; i < n; i++)
    printf("%s%d", i ? ", " : "", array[i]);
  printf("]\n");
  return 0;
}
