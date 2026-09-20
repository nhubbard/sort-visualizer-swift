#include <stdio.h>
#include <stdlib.h>

#define RECENCY 8
#define EARLY_OUT_TEST_AT 4
#define EARLY_OUT_DISORDER_FRACTION 0.6

int array[30] = {0,  1,  2,  3,  4,  9,  6,  7,  8,  5,  10, 11, 12, 13, 14,
                 15, 21, 17, 18, 19, 20, 16, 22, 23, 24, 28, 26, 27, 25, 29};

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

/* Branched PDQ fallback, matching the app’s PDQSortingTemplate. */
#define INSERT_SORT_THRESHOLD 24
#define NINTHER_THRESHOLD 128
#define PARTIAL_INSERT_SORT_LIMIT 8

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

typedef struct {
  int pivotPos;
  int alreadyParted;
} PDQPair;

int pdqLog(int n);
void insertSort(int arr[], int begin, int end);
void unguardInsertSort(int arr[], int begin, int end);
int partialInsertSort(int arr[], int begin, int end);
void sortTwo(int arr[], int a, int b);
void sortThree(int arr[], int a, int b, int c);
PDQPair partRight(int arr[], int begin, int end);
int partLeft(int arr[], int begin, int end);
void siftDown(int arr[], int begin, int root, int size);
void heapSort(int arr[], int begin, int end);
void pdqLoop(int arr[], int begin, int end, int badAllowed);
void pdqSort(int arr[], int begin, int end);

void sort(int arr[], int length) {
  if (length < 2) {
    return;
  }

  /* `dropped` is grown one element at a time via droppedCount and shrunk during
   * backtrack by simply decrementing droppedCount -- it can never hold more
   * than `length` elements. */
  int *dropped = malloc(length * sizeof(int));
  int droppedCount = 0;
  int numDroppedInARow = 0;
  int read = 0;
  int write = 0;
  int iteration = 0;
  int earlyOutStop = length / EARLY_OUT_TEST_AT;

  while (read < length) {
    iteration++;
    if (iteration == earlyOutStop &&
        droppedCount > read * EARLY_OUT_DISORDER_FRACTION) {
      /* Too disordered for the adaptive approach to be worth it: flush what's
       * been dropped so far back into the array and fall back to a plain full
       * sort. */
      for (int i = 0; i < droppedCount; i++) {
        arr[write] = dropped[i];
        write++;
      }
      droppedCount = 0;
      pdqSort(arr, 0, length);
      free(dropped);
      return;
    }

    if (write == 0 || arr[read] >= arr[write - 1]) {
      /* In order -- keep it. */
      arr[write] = arr[read];
      write++;
      read++;
      numDroppedInARow = 0;
    } else if (numDroppedInARow == 0 && write >= 2 &&
               arr[read] >= arr[write - 2]) {
      /* Quick undo: the element two back would have accepted this one just
       * fine, so drop the one right before it instead of the new element. */
      dropped[droppedCount++] = arr[write - 1];
      arr[write - 1] = arr[read];
      read++;
    } else if (numDroppedInARow < RECENCY) {
      dropped[droppedCount++] = arr[read];
      read++;
      numDroppedInARow++;
    } else {
      /* Accepting something `numDroppedInARow` elements back made every
       * subsequent element drop -- that accept was a mistake. Undo it, and any
       * other recently accepted elements bigger than the dropped run's maximum.
       */
      droppedCount -= numDroppedInARow;
      read -= numDroppedInARow;

      int numBacktracked = 1;
      write--;

      int maxOfDropped = read;
      for (int i = read + 1; i <= read + numDroppedInARow; i++) {
        if (arr[i] > maxOfDropped) {
          maxOfDropped = arr[i];
        }
      }

      while (write >= 1 && maxOfDropped < arr[write - 1]) {
        write--;
        numBacktracked++;
      }

      for (int i = write; i < write + numBacktracked; i++) {
        dropped[droppedCount++] = arr[i];
      }

      numDroppedInARow = 0;
    }
  }

  for (int offset = 0; offset < droppedCount; offset++) {
    arr[write + offset] = dropped[offset];
  }

  pdqSort(arr, write, length);

  /* Copy the now-sorted dropped tail before the final backward merge starts
   * overwriting arr[write:] in place. */
  int *buffer = malloc(droppedCount * sizeof(int));
  for (int i = 0; i < droppedCount; i++) {
    buffer[i] = arr[write + i];
  }

  int i = droppedCount - 1;
  int j = write - 1;
  int k = length - 1;

  while (i >= 0) {
    if (j < 0 || buffer[i] > arr[j]) {
      arr[k] = buffer[i];
      k--;
      i--;
    } else {
      arr[k] = arr[j];
      k--;
      j--;
    }
  }

  free(buffer);
  free(dropped);
}

int pdqLog(int n) {
  int log = 0;
  while ((n >>= 1) != 0)
    log++;
  return log;
}

void insertSort(int arr[], int begin, int end) {
  for (int cur = begin + 1; cur < end; cur++) {
    if (arr[cur] < arr[cur - 1]) {
      int tmp = arr[cur];
      int sift = cur;
      int siftMinusOne = cur - 1;
      do {
        arr[sift--] = arr[siftMinusOne--];
      } while (sift != begin && tmp < arr[siftMinusOne]);
      arr[sift] = tmp;
    }
  }
}

void unguardInsertSort(int arr[], int begin, int end) {
  for (int cur = begin + 1; cur < end; cur++) {
    if (arr[cur] < arr[cur - 1]) {
      int tmp = arr[cur];
      int sift = cur;
      int siftMinusOne = cur - 1;
      do {
        arr[sift--] = arr[siftMinusOne--];
      } while (tmp < arr[siftMinusOne]);
      arr[sift] = tmp;
    }
  }
}

int partialInsertSort(int arr[], int begin, int end) {
  int limit = 0;
  for (int cur = begin + 1; cur < end; cur++) {
    if (limit > PARTIAL_INSERT_SORT_LIMIT)
      return 0;
    if (arr[cur] < arr[cur - 1]) {
      int tmp = arr[cur];
      int sift = cur;
      int siftMinusOne = cur - 1;
      do {
        arr[sift--] = arr[siftMinusOne--];
      } while (sift != begin && tmp < arr[siftMinusOne]);
      arr[sift] = tmp;
      limit += cur - sift;
    }
  }
  return 1;
}

void sortTwo(int arr[], int a, int b) {
  if (arr[b] < arr[a])
    swap(&arr[a], &arr[b]);
}

void sortThree(int arr[], int a, int b, int c) {
  sortTwo(arr, a, b);
  sortTwo(arr, b, c);
  sortTwo(arr, a, b);
}

PDQPair partRight(int arr[], int begin, int end) {
  int pivot = arr[begin];
  int first = begin;
  int last = end;

  first++;
  while (arr[first] < pivot)
    first++;

  if (first - 1 == begin) {
    last--;
    while (first < last && !(arr[last] < pivot))
      last--;
  } else {
    last--;
    while (!(arr[last] < pivot))
      last--;
  }

  int alreadyParted = first >= last;
  while (first < last) {
    swap(&arr[first], &arr[last]);
    first++;
    while (arr[first] < pivot)
      first++;
    last--;
    while (!(arr[last] < pivot))
      last--;
  }

  int pivotPos = first - 1;
  arr[begin] = arr[pivotPos];
  arr[pivotPos] = pivot;

  PDQPair result = {pivotPos, alreadyParted};
  return result;
}

int partLeft(int arr[], int begin, int end) {
  int pivot = arr[begin];
  int first = begin;
  int last = end;

  last--;
  while (pivot < arr[last])
    last--;

  if (last + 1 == end) {
    first++;
    while (first < last && !(pivot < arr[first]))
      first++;
  } else {
    first++;
    while (!(pivot < arr[first]))
      first++;
  }

  while (first < last) {
    swap(&arr[first], &arr[last]);
    last--;
    while (pivot < arr[last])
      last--;
    first++;
    while (!(pivot < arr[first]))
      first++;
  }

  int pivotPos = last;
  arr[begin] = arr[pivotPos];
  arr[pivotPos] = pivot;
  return pivotPos;
}

void siftDown(int arr[], int begin, int root, int size) {
  while (1) {
    int child = 2 * root + 1;
    if (child >= size)
      break;
    if (child + 1 < size && arr[begin + child] < arr[begin + child + 1])
      child++;
    if (arr[begin + root] < arr[begin + child]) {
      swap(&arr[begin + root], &arr[begin + child]);
      root = child;
    } else {
      break;
    }
  }
}

void heapSort(int arr[], int begin, int end) {
  int n = end - begin;
  for (int i = n / 2 - 1; i >= 0; i--)
    siftDown(arr, begin, i, n);
  for (int i = n - 1; i > 0; i--) {
    swap(&arr[begin], &arr[begin + i]);
    siftDown(arr, begin, 0, i);
  }
}

void pdqLoop(int arr[], int begin, int end, int badAllowed) {
  int leftmost = 1;
  while (1) {
    int size = end - begin;

    if (size < INSERT_SORT_THRESHOLD) {
      if (leftmost)
        insertSort(arr, begin, end);
      else
        unguardInsertSort(arr, begin, end);
      return;
    }

    int halfSize = size / 2;
    if (size > NINTHER_THRESHOLD) {
      sortThree(arr, begin, begin + halfSize, end - 1);
      sortThree(arr, begin + 1, begin + halfSize - 1, end - 2);
      sortThree(arr, begin + 2, begin + halfSize + 1, end - 3);
      sortThree(arr, begin + halfSize - 1, begin + halfSize,
                begin + halfSize + 1);
      swap(&arr[begin], &arr[begin + halfSize]);
    } else {
      sortThree(arr, begin + halfSize, begin, end - 1);
    }

    if (!leftmost && !(arr[begin - 1] < arr[begin])) {
      begin = partLeft(arr, begin, end) + 1;
      continue;
    }

    PDQPair partResult = partRight(arr, begin, end);
    int pivotPos = partResult.pivotPos;
    int alreadyParted = partResult.alreadyParted;

    int leftSize = pivotPos - begin;
    int rightSize = end - (pivotPos + 1);
    int highUnbalance = leftSize < size / 8 || rightSize < size / 8;

    if (highUnbalance) {
      if (--badAllowed == 0) {
        heapSort(arr, begin, end);
        return;
      }

      if (leftSize >= INSERT_SORT_THRESHOLD) {
        swap(&arr[begin], &arr[begin + leftSize / 4]);
        swap(&arr[pivotPos - 1], &arr[pivotPos - leftSize / 4]);
        if (leftSize > NINTHER_THRESHOLD) {
          swap(&arr[begin + 1], &arr[begin + (leftSize / 4 + 1)]);
          swap(&arr[begin + 2], &arr[begin + (leftSize / 4 + 2)]);
          swap(&arr[pivotPos - 2], &arr[pivotPos - (leftSize / 4 + 1)]);
          swap(&arr[pivotPos - 3], &arr[pivotPos - (leftSize / 4 + 2)]);
        }
      }

      if (rightSize >= INSERT_SORT_THRESHOLD) {
        swap(&arr[pivotPos + 1], &arr[pivotPos + (1 + rightSize / 4)]);
        swap(&arr[end - 1], &arr[end - rightSize / 4]);
        if (rightSize > NINTHER_THRESHOLD) {
          swap(&arr[pivotPos + 2], &arr[pivotPos + (2 + rightSize / 4)]);
          swap(&arr[pivotPos + 3], &arr[pivotPos + (3 + rightSize / 4)]);
          swap(&arr[end - 2], &arr[end - (1 + rightSize / 4)]);
          swap(&arr[end - 3], &arr[end - (2 + rightSize / 4)]);
        }
      }
    } else {
      if (alreadyParted && partialInsertSort(arr, begin, pivotPos) &&
          partialInsertSort(arr, pivotPos + 1, end)) {
        return;
      }
    }

    pdqLoop(arr, begin, pivotPos, badAllowed);
    begin = pivotPos + 1;
    leftmost = 0;
  }
}

void pdqSort(int arr[], int begin, int end) {
  if (end - begin > 1) pdqLoop(arr, begin, end, pdqLog(end - begin));
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
