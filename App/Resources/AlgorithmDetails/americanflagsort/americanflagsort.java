import java.util.Arrays;

public class americanflagsort {
  private static int digitAt(int value, int divisor, int radix) {
    return (value / divisor) % radix;
  }

  private static void flagSort(int[] array, int low, int high, int divisor, int radix) {
    if (high - low <= 1) {
      return;
    }

    int[] count = new int[radix];
    int[] offset = new int[radix];

    for (int i = low; i < high; i++) {
      count[digitAt(array[i], divisor, radix)]++;
    }

    offset[0] = low;
    for (int d = 1; d < radix; d++) {
      offset[d] = offset[d - 1] + count[d - 1];
    }
    int[] bucketStart = Arrays.copyOf(offset, radix);

    for (int d = 0; d < radix; d++) {
      while (count[d] > 0) {
        int origin = offset[d];
        int from = origin;
        int value = array[from];

        do {
          int digit = digitAt(value, divisor, radix);
          int dest = offset[digit]++;
          count[digit]--;
          int displaced = array[dest];
          array[dest] = value;
          value = displaced;
          from = dest;
        } while (from != origin);
      }
    }

    if (divisor > 1) {
      for (int d = 0; d < radix; d++) {
        int begin = bucketStart[d];
        int end = offset[d];
        if (end - begin > 1) {
          flagSort(array, begin, end, divisor / radix, radix);
        }
      }
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n <= 1) {
      return;
    }

    int radix = 10;
    int maxValue = arr[0];
    for (int value : arr) {
      if (value > maxValue) {
        maxValue = value;
      }
    }

    int divisor = 1;
    while (maxValue / divisor >= radix) {
      divisor *= radix;
    }

    flagSort(arr, 0, n, divisor, radix);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
