#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

#define INSERT_SORT_THRESHOLD 24
#define NINTHER_THRESHOLD 128
#define PARTIAL_INSERT_SORT_LIMIT 8
#define BLOCK_SIZE 64
#define CACHELINE_SIZE 64

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

typedef struct {
  int pivotPos;
  int alreadyParted;
} PDQPair;

int pdqLog(int n) {
  int log = 0;
  while ((n >>= 1) != 0)
    log++;
  return log;
}

/* Integer division truncated toward zero. C's `/` already truncates toward zero
   for negative operands, which is what the pivot-position arithmetic below
   needs at the one call site where the dividend can go negative -- this helper
   just names that intent. */
int truncDiv(int a, int b) { return a / b; }

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

void swapOffsets(int arr[], int first, int last, int leftOffsets[], int leftPos,
                 int rightOffsets[], int rightPos, int num, int useSwaps) {
  if (useSwaps) {
    for (int i = 0; i < num; i++) {
      swap(&arr[first + leftOffsets[leftPos + i]],
           &arr[last - rightOffsets[rightPos + i]]);
    }
  } else if (num > 0) {
    int left = first + leftOffsets[leftPos];
    int right = last - rightOffsets[rightPos];
    int tmp = arr[left];
    arr[left] = arr[right];
    for (int i = 1; i < num; i++) {
      left = first + leftOffsets[leftPos + i];
      arr[right] = arr[left];
      right = last - rightOffsets[rightPos + i];
      arr[left] = arr[right];
    }
    arr[right] = tmp;
  }
}

PDQPair partRightBranchless(int arr[], int begin, int end, int leftOffsets[],
                            int rightOffsets[]) {
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
  if (!alreadyParted) {
    swap(&arr[first], &arr[last]);
    first++;
  }

  int leftNum = 0, rightNum = 0, leftStart = 0, rightStart = 0;

  while (last - first > 2 * BLOCK_SIZE) {
    if (leftNum == 0) {
      leftStart = 0;
      int it = first;
      for (int i = 0; i < BLOCK_SIZE; i++) {
        leftOffsets[leftNum] = i;
        if (!(arr[it] < pivot))
          leftNum++;
        it++;
      }
    }
    if (rightNum == 0) {
      rightStart = 0;
      int it = last;
      for (int i = 0; i < BLOCK_SIZE; i++) {
        it--;
        rightOffsets[rightNum] = i + 1;
        if (arr[it] < pivot)
          rightNum++;
      }
    }

    int num = leftNum < rightNum ? leftNum : rightNum;
    swapOffsets(arr, first, last, leftOffsets, leftStart, rightOffsets,
                rightStart, num, leftNum == rightNum);
    leftNum -= num;
    rightNum -= num;
    leftStart += num;
    rightStart += num;
    if (leftNum == 0)
      first += BLOCK_SIZE;
    if (rightNum == 0)
      last -= BLOCK_SIZE;
  }

  int leftSize = 0, rightSize = 0;
  int unknownLeft =
      (last - first) - ((rightNum != 0 || leftNum != 0) ? BLOCK_SIZE : 0);
  if (rightNum != 0) {
    leftSize = unknownLeft;
    rightSize = BLOCK_SIZE;
  } else if (leftNum != 0) {
    leftSize = BLOCK_SIZE;
    rightSize = unknownLeft;
  } else {
    leftSize = truncDiv(unknownLeft, 2);
    rightSize = unknownLeft - leftSize;
  }

  if (unknownLeft != 0 && leftNum == 0) {
    leftStart = 0;
    int it = first;
    for (int i = 0; i < leftSize; i++) {
      leftOffsets[leftNum] = i;
      if (!(arr[it] < pivot))
        leftNum++;
      it++;
    }
  }

  if (unknownLeft != 0 && rightNum == 0) {
    rightStart = 0;
    int it = last;
    for (int i = 0; i < rightSize; i++) {
      it--;
      rightOffsets[rightNum] = i + 1;
      if (arr[it] < pivot)
        rightNum++;
    }
  }

  int num = leftNum < rightNum ? leftNum : rightNum;
  swapOffsets(arr, first, last, leftOffsets, leftStart, rightOffsets,
              rightStart, num, leftNum == rightNum);
  leftNum -= num;
  rightNum -= num;
  leftStart += num;
  rightStart += num;
  if (leftNum == 0)
    first += leftSize;
  if (rightNum == 0)
    last -= rightSize;

  int leftOffsetsPos = 0;
  int rightOffsetsPos = 0;

  if (leftNum != 0) {
    leftOffsetsPos += leftStart;
    while (leftNum-- != 0) {
      swap(&arr[first + leftOffsets[leftOffsetsPos + leftNum]], &arr[--last]);
    }
    first = last;
  }

  if (rightNum != 0) {
    rightOffsetsPos += rightStart;
    while (rightNum-- != 0) {
      swap(&arr[last - rightOffsets[rightOffsetsPos + rightNum]],
           &arr[first++]);
    }
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

void pdqLoop(int arr[], int begin, int end, int badAllowed, int leftOffsets[],
             int rightOffsets[]) {
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

    PDQPair partResult =
        partRightBranchless(arr, begin, end, leftOffsets, rightOffsets);
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

    pdqLoop(arr, begin, pivotPos, badAllowed, leftOffsets, rightOffsets);
    begin = pivotPos + 1;
    leftmost = 0;
  }
}

void sort(int arr[], int n) {
  if (n < 2)
    return;
  int leftOffsets[BLOCK_SIZE + CACHELINE_SIZE];
  int rightOffsets[BLOCK_SIZE + CACHELINE_SIZE];
  pdqLoop(arr, 0, n, pdqLog(n), leftOffsets, rightOffsets);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
