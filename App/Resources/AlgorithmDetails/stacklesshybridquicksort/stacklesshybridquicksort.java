import java.util.Arrays;

public class stacklesshybridquicksort {
  static final int INSERTION_THRESHOLD = 16;

  // Arranges arr[start], arr[mid], arr[end - 1] so the median of the three ends up at `start`,
  // ready to serve as partition's pivot.
  static void medianOfThree(int[] arr, int start, int end) {
    int mid = start + (end - 1 - start) / 2;
    if (arr[start] > arr[mid]) {
      int t = arr[start];
      arr[start] = arr[mid];
      arr[mid] = t;
    }
    if (arr[mid] > arr[end - 1]) {
      int t = arr[mid];
      arr[mid] = arr[end - 1];
      arr[end - 1] = t;
      if (arr[start] > arr[mid]) {
        return;
      }
    }
    int t = arr[start];
    arr[start] = arr[mid];
    arr[mid] = t;
  }

  // Classic two-pointer Hoare partition against the pivot medianOfThree just placed at `start`.
  // Returns the pivot's final resting index.
  static int partition(int[] arr, int start, int end) {
    medianOfThree(arr, start, end);
    int pivot = arr[start];
    int i = start;
    int j = end;

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
        int t = arr[i];
        arr[i] = arr[j];
        arr[j] = t;
      } else {
        int t = arr[start];
        arr[start] = arr[j];
        arr[j] = t;
        return j;
      }
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

  // Sorts arr[start..end) in place with no recursion: a single loop processes one segment at a
  // time, shrinking and partitioning it down to INSERTION_THRESHOLD elements, finishing with
  // binaryInsertionSort, then advancing past it to the next segment.
  static void quickSort(int[] arr, int start, int end) {
    // Move every copy of this range's maximum value to the very end first. Those elements are
    // already correctly placed relative to everything else, so the rest of the algorithm never
    // has to look at them again -- and the boundary in front of them becomes the fixed resting
    // place partition sends each finished pivot out to.
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
    // should refresh its candidates, since reusing them would just compare equal again.
    boolean refreshMedian = true;

    while (true) {
      while (segmentEnd - a > INSERTION_THRESHOLD) {
        if (refreshMedian) {
          medianOfThree(arr, a, segmentEnd);
        }
        int pivotIndex = partition(arr, a, segmentEnd);
        int t = arr[pivotIndex];
        arr[pivotIndex] = arr[tail];
        arr[tail] = t;
        segmentEnd = pivotIndex;
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
