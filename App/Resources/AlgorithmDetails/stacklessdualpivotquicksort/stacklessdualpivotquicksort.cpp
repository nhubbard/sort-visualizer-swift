#include <cstdio>
#include <utility>

constexpr int kInsertionThreshold = 24;

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

// Dual-pivot partition of arr[start..end). `scratch` is a fixed index outside
// this range, borrowed briefly as scratch space by the closing rotation and
// immediately restored. Returns the boundary between the low region and
// everything at or above the smaller of the two pivots.
int partition(int arr[], int start, int end, int scratch) {
  int m1 = (start + start + end) / 3;
  int m2 = (start + end + end) / 3;

  if (arr[m1] > arr[m2]) {
    std::swap(arr[m1], arr[start]);
    end--;
    std::swap(arr[m2], arr[end]);
  } else {
    std::swap(arr[m2], arr[start]);
    end--;
    std::swap(arr[m1], arr[end]);
  }

  int low = start;
  int high = end;
  // Reversed from the usual low/high naming: after the swaps above, `start`
  // holds the larger of the two chosen medians and `end` the smaller. Neither
  // position moves again until the closing rotation below, so their values are
  // safe to hold onto directly.
  int pivotMax = arr[start];
  int pivotMin = arr[end];

  int k = low + 1;
  while (k < high) {
    if (arr[k] < pivotMin) {
      low++;
      std::swap(arr[k], arr[low]);
    } else if (arr[k] >= pivotMax) {
      do {
        high--;
      } while (high > k && arr[high] >= pivotMax);
      std::swap(arr[k], arr[high]);
      if (arr[k] < pivotMin) {
        low++;
        std::swap(arr[k], arr[low]);
      }
    }
    k++;
  }

  std::swap(arr[start], arr[low]);
  // Three-way rotation: the value at `end` moves to `scratch`, whatever was
  // borrowed from `scratch` moves to `high`, and whatever was at `high` moves
  // to `end`.
  int displaced = arr[end];
  arr[end] = arr[high];
  arr[high] = arr[scratch];
  arr[scratch] = displaced;

  return low;
}

// Sorts arr[start..end) in place with no recursion: a single loop processes one
// segment at a time, shrinking and partitioning it down to kInsertionThreshold
// elements, finishing with binaryInsertionSort, then advancing past it to the
// next segment.
void quickSort(int arr[], int start, int end) {
  // Move every copy of this range's maximum value to the very end first. Those
  // elements are already correctly placed relative to everything else, so the
  // rest of the algorithm never has to look at them again -- and the boundary
  // in front of them becomes fixed scratch space `partition` can borrow from.
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
  // median-of-three should refresh one of its two candidates, since reusing
  // them would just compare equal again.
  bool reuseMedianCandidates = true;

  while (true) {
    while (segmentEnd - a > kInsertionThreshold) {
      if (!reuseMedianCandidates) {
        int m = (a + a + segmentEnd) / 3;
        std::swap(arr[a], arr[m]);
      }
      segmentEnd = partition(arr, a, segmentEnd, tail);
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

    reuseMedianCandidates = true;
    while (a < segmentEnd && arr[a - 1] == arr[a]) {
      reuseMedianCandidates = false;
      a++;
    }
    if (a == segmentEnd) {
      reuseMedianCandidates = true;
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
