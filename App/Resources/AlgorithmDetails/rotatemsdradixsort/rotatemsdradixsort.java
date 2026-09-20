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
  private static int shift(int value, int places, int base) {
    while (places-- > 0) value /= base;
    return value;
  }

  private static int dist(int[] arr, int a, int b, int place, int base) {
    mergeSortDigit(arr, a, b, place, base);
    return binSearchDigit(arr, a, b, 1, place, base);
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n <= 1) return;
    int base = 4, maxValue = 0;
    for (int value : arr) if (value > maxValue) maxValue = value;
    int q = 0, probe = base;
    while (probe <= maxValue) { q++; probe *= base; }
    int m = 0, i = 0, b = n;
    while (i < n) {
      int p = b - i < 1 ? i : dist(arr, i, b, q, base);
      if (q == 0) {
        m += base;
        int t = m / base;
        while (t % base == 0) { t /= base; q++; }
        i = b;
        while (b < n && shift(arr[b], q + 1, base) == shift(m, q + 1, base)) b++;
      } else { b = p; q--; }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
