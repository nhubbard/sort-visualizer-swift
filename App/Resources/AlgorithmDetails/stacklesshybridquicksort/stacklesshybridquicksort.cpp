#include <cstdio>
#include <utility>

constexpr int kInsertionThreshold = 16;

int array[30] = {55, 12, 84, 3, 47, 91, 26, 68, 8,  73, 40, 97, 15, 62, 34,
                 79, 21, 88, 5, 51, 66, 29, 44, 12, 78, 33, 91, 6,  58, 12};

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

// Arranges arr[start], arr[mid], arr[end - 1] so the median of the three ends
// up at `start`, ready to serve as partition's pivot.
void medianOfThree(int arr[], int start, int end) {
  int mid = start + (end - 1 - start) / 2;
  if (arr[start] > arr[mid]) {
    std::swap(arr[start], arr[mid]);
  }
  if (arr[mid] > arr[end - 1]) {
    std::swap(arr[mid], arr[end - 1]);
    if (arr[start] > arr[mid]) {
      return;
    }
  }
  std::swap(arr[start], arr[mid]);
}

// Classic two-pointer Hoare partition against the pivot medianOfThree just
// placed at `start`. Returns the pivot's final resting index.
int partition(int arr[], int start, int end) {
  medianOfThree(arr, start, end);
  int pivot = arr[start];
  int i = start, j = end;

  while (true) {
    i++;
    while (i < j && arr[i] < pivot) {
      i++;
    }
    j--;
    while (j >= i && arr[j] >= pivot) {
      j--;
    }
    if (i < j) {
      std::swap(arr[i], arr[j]);
    } else {
      std::swap(arr[start], arr[j]);
      return j;
    }
  }
}

// Finds where the value at targetIndex belongs among arr[start..end), ties
// resolving toward the front (a plain lower-bound binary search).
int lowerBoundIndex(int arr[], int start, int end, int targetIndex) {
  int lo = start, hi = end;
  while (lo < hi) {
    int mid = lo + (hi - lo) / 2;
    if (arr[targetIndex] <= arr[mid]) {
      hi = mid;
    } else {
      lo = mid + 1;
    }
  }
  return lo;
}

// Sorts arr[start..end) in place using a plain binary-search insertion sort --
// the base case once a segment shrinks small enough that further partitioning
// isn't worth it.
void binaryInsertionSort(int arr[], int start, int end) {
  for (int i = start; i < end; i++) {
    int value = arr[i];
    int lo = start, hi = i;
    while (lo < hi) {
      int mid = lo + (hi - lo) / 2;
      if (value < arr[mid]) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    int j = i - 1;
    while (j >= lo) {
      arr[j + 1] = arr[j];
      j--;
    }
    arr[lo] = value;
  }
}

// Sorts arr[start..end) in place with no recursion: a single loop processes
// one segment at a time, shrinking and partitioning it down to
// kInsertionThreshold elements, finishing with binaryInsertionSort, then
// advancing past it to the next segment.
void quickSort(int arr[], int start, int end) {
  // Move every copy of this range's maximum value to the very end first.
  // Those elements are already correctly placed relative to everything else,
  // so the rest of the algorithm never has to look at them again -- and the
  // boundary in front of them becomes the fixed resting place partition sends
  // each finished pivot out to.
  int maxValue = arr[start];
  for (int i = start + 1; i < end; i++) {
    if (arr[i] > maxValue) {
      maxValue = arr[i];
    }
  }

  int tail = end;
  for (int i = end - 1; i >= start; i--) {
    if (arr[i] == maxValue) {
      tail--;
      std::swap(arr[i], arr[tail]);
    }
  }

  int a = start;
  int segmentEnd = tail;
  // False right after skipping a run of duplicates below means the next
  // median-of-three should refresh its candidates, since reusing them would
  // just compare equal again.
  bool refreshMedian = true;

  while (true) {
    while (segmentEnd - a > kInsertionThreshold) {
      if (refreshMedian) {
        medianOfThree(arr, a, segmentEnd);
      }
      int pivotIndex = partition(arr, a, segmentEnd);
      std::swap(arr[pivotIndex], arr[tail]);
      segmentEnd = pivotIndex;
    }

    binaryInsertionSort(arr, a, segmentEnd);

    a = segmentEnd + 1;
    if (a >= tail) {
      if (a - 1 < tail) {
        std::swap(arr[a - 1], arr[tail]);
      }
      return;
    }

    segmentEnd = lowerBoundIndex(arr, a, tail, a - 1);
    std::swap(arr[a - 1], arr[tail]);

    refreshMedian = true;
    while (a < segmentEnd && arr[a - 1] == arr[a]) {
      refreshMedian = false;
      a++;
    }
    if (a == segmentEnd) {
      refreshMedian = true;
    }
  }
}

void sort(int arr[], int n) {
  if (n < 2) {
    return;
  }
  quickSort(arr, 0, n);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
