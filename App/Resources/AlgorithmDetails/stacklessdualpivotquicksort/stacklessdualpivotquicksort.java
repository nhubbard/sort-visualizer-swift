import java.util.Arrays;

public class stacklessdualpivotquicksort {
  static final int INSERTION_THRESHOLD = 24;

  // Sorts arr[start..end) in place using a plain binary-search insertion sort -- the base case
  // once a segment shrinks small enough that further partitioning isn't worth it.
  static void binaryInsertionSort(int[] arr, int start, int end) {
    for (int i = start; i < end; i++) {
      int value = arr[i];
      int lo = start;
      int hi = i;
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

  // Finds where the value at targetIndex belongs among arr[start..end), ties resolving toward
  // the front (a plain lower-bound binary search).
  static int lowerBoundIndex(int[] arr, int start, int end, int targetIndex) {
    int lo = start;
    int hi = end;
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

  // Dual-pivot partition of arr[start..end). `scratch` is a fixed index outside this range,
  // borrowed briefly as scratch space by the closing rotation and immediately restored. Returns
  // the boundary between the low region and everything at or above the smaller of the two
  // pivots.
  static int partition(int[] arr, int start, int end, int scratch) {
    int m1 = (start + start + end) / 3;
    int m2 = (start + end + end) / 3;

    if (arr[m1] > arr[m2]) {
      int t = arr[m1];
      arr[m1] = arr[start];
      arr[start] = t;
      end--;
      int t2 = arr[m2];
      arr[m2] = arr[end];
      arr[end] = t2;
    } else {
      int t = arr[m2];
      arr[m2] = arr[start];
      arr[start] = t;
      end--;
      int t2 = arr[m1];
      arr[m1] = arr[end];
      arr[end] = t2;
    }

    int low = start;
    int high = end;
    // Reversed from the usual low/high naming: after the swaps above, `start` holds the larger
    // of the two chosen medians and `end` the smaller. Neither position moves again until the
    // closing rotation below, so their values are safe to hold onto directly.
    int pivotMax = arr[start];
    int pivotMin = arr[end];

    int k = low + 1;
    while (k < high) {
      if (arr[k] < pivotMin) {
        low++;
        int t = arr[k];
        arr[k] = arr[low];
        arr[low] = t;
      } else if (arr[k] >= pivotMax) {
        do {
          high--;
        } while (high > k && arr[high] >= pivotMax);
        int t = arr[k];
        arr[k] = arr[high];
        arr[high] = t;
        if (arr[k] < pivotMin) {
          low++;
          int t2 = arr[k];
          arr[k] = arr[low];
          arr[low] = t2;
        }
      }
      k++;
    }

    int t = arr[start];
    arr[start] = arr[low];
    arr[low] = t;
    // Three-way rotation: the value at `end` moves to `scratch`, whatever was borrowed from
    // `scratch` moves to `high`, and whatever was at `high` moves to `end`.
    int displaced = arr[end];
    arr[end] = arr[high];
    arr[high] = arr[scratch];
    arr[scratch] = displaced;

    return low;
  }

  // Sorts arr[start..end) in place with no recursion: a single loop processes one segment at a
  // time, shrinking and partitioning it down to INSERTION_THRESHOLD elements, finishing with
  // binaryInsertionSort, then advancing past it to the next segment.
  static void quickSort(int[] arr, int start, int end) {
    // Move every copy of this range's maximum value to the very end first. Those elements are
    // already correctly placed relative to everything else, so the rest of the algorithm never
    // has to look at them again -- and the boundary in front of them becomes fixed scratch
    // space partition can borrow from.
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
        int t = arr[i];
        arr[i] = arr[tail];
        arr[tail] = t;
      }
    }

    int a = start;
    int segmentEnd = tail;
    // False right after skipping a run of duplicates below means the next median-of-three
    // should refresh one of its two candidates, since reusing them would just compare equal
    // again.
    boolean reuseMedianCandidates = true;

    while (true) {
      while (segmentEnd - a > INSERTION_THRESHOLD) {
        if (!reuseMedianCandidates) {
          int m = (a + a + segmentEnd) / 3;
          int t = arr[a];
          arr[a] = arr[m];
          arr[m] = t;
        }
        segmentEnd = partition(arr, a, segmentEnd, tail);
      }

      binaryInsertionSort(arr, a, segmentEnd);

      a = segmentEnd + 1;
      if (a >= tail) {
        if (a - 1 < tail) {
          int t = arr[a - 1];
          arr[a - 1] = arr[tail];
          arr[tail] = t;
        }
        return;
      }

      segmentEnd = lowerBoundIndex(arr, a, tail, a - 1);
      int t = arr[a - 1];
      arr[a - 1] = arr[tail];
      arr[tail] = t;

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

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n < 2) {
      return;
    }
    quickSort(arr, 0, n);
  }

  public static void main(String[] args) {
    int[] array =
        new int[] {
          55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79, 21, 88, 5, 51, 66, 29, 44,
          12, 78, 33, 91, 6, 58, 12
        };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
