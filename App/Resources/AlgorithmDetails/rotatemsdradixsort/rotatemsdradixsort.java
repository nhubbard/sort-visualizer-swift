import java.util.Arrays;

public class rotatemsdradixsort {
  private static int intPow(int base, int exponent) {
    int result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  private static int getDigit(int value, int place, int base) {
    return (value / intPow(base, place)) % base;
  }

  private static void multiSwap(int[] arr, int a, int b, int len) {
    for (int i = 0; i < len; i++) {
      int t = arr[a + i];
      arr[a + i] = arr[b + i];
      arr[b + i] = t;
    }
  }

  private static void rotate(int[] arr, int a, int m, int b) {
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

  private static int binSearchDigit(int[] arr, int a, int b, int d, int place, int base) {
    while (a < b) {
      int mid = (a + b) / 2;
      if (getDigit(arr[mid], place, base) >= d) {
        b = mid;
      } else {
        a = mid + 1;
      }
    }
    return a;
  }

  private static void mergeDigit(
      int[] arr, int a, int m, int b, int da, int db, int place, int base) {
    if (b - a < 2 || db - da < 2) {
      return;
    }
    int dm = (da + db) / 2;
    int m1 = binSearchDigit(arr, a, m, dm, place, base);
    int m2 = binSearchDigit(arr, m, b, dm, place, base);
    rotate(arr, m1, m, m2);
    int newM = m1 + (m2 - m);
    mergeDigit(arr, newM, m2, b, dm, db, place, base);
    mergeDigit(arr, a, m1, newM, da, dm, place, base);
  }

  private static void mergeSortDigit(int[] arr, int a, int b, int place, int base) {
    if (b - a < 2) {
      return;
    }
    int mid = (a + b) / 2;
    mergeSortDigit(arr, a, mid, place, base);
    mergeSortDigit(arr, mid, b, place, base);
    mergeDigit(arr, a, mid, b, 0, base, place, base);
  }

  // Digit-sorts [a, b) in place by `place` using rotation instead of counting
  // buckets, then recurses into every resulting digit bucket one place lower --
  // an ordinary MSD radix sort built entirely out of the LSD variant's
  // rotate/binary-search machinery.
  private static void msdRotateSort(int[] arr, int a, int b, int place, int base) {
    if (b - a < 2 || place < 0) {
      return;
    }
    mergeSortDigit(arr, a, b, place, base);
    int start = a;
    for (int d = 0; d < base; d++) {
      int end = binSearchDigit(arr, start, b, d + 1, place, base);
      msdRotateSort(arr, start, end, place - 1, base);
      start = end;
    }
  }

  public static void sort(int[] arr) {
    if (arr.length <= 1) {
      return;
    }
    int base = 4;
    int maxValue = arr[0];
    for (int value : arr) {
      if (value > maxValue) {
        maxValue = value;
      }
    }
    int highestPlace = 0;
    int probe = base;
    while (probe <= maxValue) {
      highestPlace++;
      probe *= base;
    }
    msdRotateSort(arr, 0, arr.length, highestPlace, base);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
