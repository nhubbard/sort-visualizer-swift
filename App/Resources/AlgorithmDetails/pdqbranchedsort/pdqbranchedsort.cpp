#include <cstdio>
#include <utility>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

const int insertSortThreshold = 24;
const int nintherThreshold = 128;
const int partialInsertSortLimit = 8;

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

bool partialInsertSort(int arr[], int begin, int end) {
  int limit = 0;
  for (int cur = begin + 1; cur < end; cur++) {
    if (limit > partialInsertSortLimit)
      return false;
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
  return true;
}

void sortTwo(int arr[], int a, int b) {
  if (arr[b] < arr[a])
    std::swap(arr[a], arr[b]);
}

void sortThree(int arr[], int a, int b, int c) {
  sortTwo(arr, a, b);
  sortTwo(arr, b, c);
  sortTwo(arr, a, b);
}

std::pair<int, bool> partRight(int arr[], int begin, int end) {
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

  bool alreadyParted = first >= last;
  while (first < last) {
    std::swap(arr[first], arr[last]);
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

  return {pivotPos, alreadyParted};
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
    std::swap(arr[first], arr[last]);
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
  while (true) {
    int child = 2 * root + 1;
    if (child >= size)
      break;
    if (child + 1 < size && arr[begin + child] < arr[begin + child + 1])
      child++;
    if (arr[begin + root] < arr[begin + child]) {
      std::swap(arr[begin + root], arr[begin + child]);
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
    std::swap(arr[begin], arr[begin + i]);
    siftDown(arr, begin, 0, i);
  }
}

void pdqLoop(int arr[], int begin, int end, int badAllowed) {
  bool leftmost = true;
  while (true) {
    int size = end - begin;

    if (size < insertSortThreshold) {
      if (leftmost)
        insertSort(arr, begin, end);
      else
        unguardInsertSort(arr, begin, end);
      return;
    }

    int halfSize = size / 2;
    if (size > nintherThreshold) {
      sortThree(arr, begin, begin + halfSize, end - 1);
      sortThree(arr, begin + 1, begin + halfSize - 1, end - 2);
      sortThree(arr, begin + 2, begin + halfSize + 1, end - 3);
      sortThree(arr, begin + halfSize - 1, begin + halfSize,
                begin + halfSize + 1);
      std::swap(arr[begin], arr[begin + halfSize]);
    } else {
      sortThree(arr, begin + halfSize, begin, end - 1);
    }

    if (!leftmost && !(arr[begin - 1] < arr[begin])) {
      begin = partLeft(arr, begin, end) + 1;
      continue;
    }

    auto [pivotPos, alreadyParted] = partRight(arr, begin, end);

    int leftSize = pivotPos - begin;
    int rightSize = end - (pivotPos + 1);
    bool highUnbalance = leftSize < size / 8 || rightSize < size / 8;

    if (highUnbalance) {
      if (--badAllowed == 0) {
        heapSort(arr, begin, end);
        return;
      }

      if (leftSize >= insertSortThreshold) {
        std::swap(arr[begin], arr[begin + leftSize / 4]);
        std::swap(arr[pivotPos - 1], arr[pivotPos - leftSize / 4]);
        if (leftSize > nintherThreshold) {
          std::swap(arr[begin + 1], arr[begin + (leftSize / 4 + 1)]);
          std::swap(arr[begin + 2], arr[begin + (leftSize / 4 + 2)]);
          std::swap(arr[pivotPos - 2], arr[pivotPos - (leftSize / 4 + 1)]);
          std::swap(arr[pivotPos - 3], arr[pivotPos - (leftSize / 4 + 2)]);
        }
      }

      if (rightSize >= insertSortThreshold) {
        std::swap(arr[pivotPos + 1], arr[pivotPos + (1 + rightSize / 4)]);
        std::swap(arr[end - 1], arr[end - rightSize / 4]);
        if (rightSize > nintherThreshold) {
          std::swap(arr[pivotPos + 2], arr[pivotPos + (2 + rightSize / 4)]);
          std::swap(arr[pivotPos + 3], arr[pivotPos + (3 + rightSize / 4)]);
          std::swap(arr[end - 2], arr[end - (1 + rightSize / 4)]);
          std::swap(arr[end - 3], arr[end - (2 + rightSize / 4)]);
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
    leftmost = false;
  }
}

void sort(int arr[], int n) {
  if (n < 2)
    return;
  pdqLoop(arr, 0, n, pdqLog(n));
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
