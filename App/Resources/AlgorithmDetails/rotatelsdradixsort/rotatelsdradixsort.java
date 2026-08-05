import java.util.Arrays;

public class rotatelsdradixsort {
  private static final int RADIX_BASE = 10;

  // Extracts the digit at `place` (0 = ones place) from `value`, in RADIX_BASE.
  private static int digitAt(int value, int place) {
    int divisor = 1;
    for (int i = 0; i < place; i++) {
      divisor *= RADIX_BASE;
    }
    return (value / divisor) % RADIX_BASE;
  }

  // Swaps the two equal-length adjacent blocks [a, a+len) and [b, b+len).
  private static void multiSwap(int[] arr, int a, int b, int len) {
    for (int i = 0; i < len; i++) {
      int t = arr[a + i];
      arr[a + i] = arr[b + i];
      arr[b + i] = t;
    }
  }

  // Rotates the adjacent blocks [a, m) and [m, b) into swapped order in place,
  // using only block-swaps -- no auxiliary buffer.
  private static void rotateBlock(int[] arr, int a, int m, int b) {
    int l = m - a;
    int r = b - m;
    while (l > 0 && r > 0) {
      if (r < l) {
        multiSwap(arr, m - r, m, r);
        b -= r;
        m -= r;
        l -= r;
      } else {
        multiSwap(arr, a, m, l);
        a += l;
        m += l;
        r -= l;
      }
    }
  }

  // Finds the leftmost index in [a, b) whose digit-`place` value is >= d,
  // assuming [a, b) is already sorted by that digit.
  private static int digitLowerBound(int[] arr, int a, int b, int d, int place) {
    while (a < b) {
      int mid = (a + b) / 2;
      if (digitAt(arr[mid], place) >= d) {
        b = mid;
      } else {
        a = mid + 1;
      }
    }
    return a;
  }

  // Merges the two adjacent digit-sorted runs [a, m) and [m, b), whose digit-`place`
  // values are known to lie in [da, db), by rotating the below-threshold prefixes of
  // both runs together and recursing into the two halves that produces.
  private static void mergeByDigit(int[] arr, int a, int m, int b, int da, int db, int place) {
    if (b - a < 2 || db - da < 2) {
      return;
    }
    int dm = (da + db) / 2;
    int m1 = digitLowerBound(arr, a, m, dm, place);
    int m2 = digitLowerBound(arr, m, b, dm, place);
    rotateBlock(arr, m1, m, m2);
    int newM = m1 + (m2 - m);
    mergeByDigit(arr, newM, m2, b, dm, db, place);
    mergeByDigit(arr, a, m1, newM, da, dm, place);
  }

  // Sorts [a, b) by digit-`place` alone via ordinary merge-sort recursion on the
  // index range, merging with mergeByDigit instead of a linear merge.
  private static void digitMergeSort(int[] arr, int a, int b, int place) {
    if (b - a < 2) {
      return;
    }
    int mid = (a + b) / 2;
    digitMergeSort(arr, a, mid, place);
    digitMergeSort(arr, mid, b, place);
    mergeByDigit(arr, a, mid, b, 0, RADIX_BASE, place);
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n < 2) {
      return;
    }
    int maxValue = arr[0];
    for (int i = 1; i < n; i++) {
      if (arr[i] > maxValue) {
        maxValue = arr[i];
      }
    }
    int maxPlace = 0;
    int probe = RADIX_BASE;
    while (probe <= maxValue) {
      maxPlace++;
      probe *= RADIX_BASE;
    }
    for (int place = 0; place <= maxPlace; place++) {
      digitMergeSort(arr, 0, n, place);
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
