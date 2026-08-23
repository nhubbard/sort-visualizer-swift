import java.util.Arrays;

public class quadsort {
  static final int INSERTION_RUN = 4;

  static void insertionSortRange(int[] arr, int lo, int hi) {
    for (int i = lo + 1; i < hi; i++) {
      int key = arr[i];
      int j = i - 1;
      while (j >= lo && arr[j] > key) {
        arr[j + 1] = arr[j];
        j--;
      }
      arr[j + 1] = key;
    }
  }

  // Merges the two equal-length sorted runs source[lo, lo+runLength) and
  // source[lo+runLength, lo+2*runLength) into dest, filling from both ends toward the middle
  // at once instead of scanning front to back alone.
  static void parityMerge(int[] source, int lo, int runLength, int[] dest) {
    int left = lo;
    int right = lo + runLength;
    int leftEnd = lo + runLength - 1;
    int rightEnd = lo + 2 * runLength - 1;
    int front = lo;
    int back = lo + 2 * runLength - 1;

    for (int step = 0; step < runLength; step++) {
      if (source[left] <= source[right]) {
        dest[front] = source[left];
        left++;
      } else {
        dest[front] = source[right];
        right++;
      }
      front++;

      if (source[leftEnd] > source[rightEnd]) {
        dest[back] = source[leftEnd];
        leftEnd--;
      } else {
        dest[back] = source[rightEnd];
        rightEnd--;
      }
      back--;
    }
  }

  static void mergeRange(int[] source, int lo, int mid, int hi, int[] dest) {
    int left = lo;
    int right = mid;
    int out = lo;
    while (left < mid && right < hi) {
      if (source[left] <= source[right]) {
        dest[out] = source[left];
        left++;
      } else {
        dest[out] = source[right];
        right++;
      }
      out++;
    }
    while (left < mid) {
      dest[out] = source[left];
      left++;
      out++;
    }
    while (right < hi) {
      dest[out] = source[right];
      right++;
      out++;
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n < 2) {
      return;
    }
    int[] buffer = Arrays.copyOf(arr, n);

    for (int lo = 0; lo < n; lo += INSERTION_RUN) {
      insertionSortRange(arr, lo, Math.min(lo + INSERTION_RUN, n));
    }

    for (int runLength = INSERTION_RUN; runLength < n; runLength *= 2) {
      for (int lo = 0; lo < n; lo += runLength * 2) {
        int mid = Math.min(lo + runLength, n);
        int hi = Math.min(lo + runLength * 2, n);
        if (mid - lo == runLength && hi - mid == runLength) {
          parityMerge(arr, lo, runLength, buffer);
        } else if (mid < hi) {
          mergeRange(arr, lo, mid, hi, buffer);
        } else {
          for (int i = lo; i < mid; i++) {
            buffer[i] = arr[i];
          }
        }
      }
      System.arraycopy(buffer, 0, arr, 0, n);
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
