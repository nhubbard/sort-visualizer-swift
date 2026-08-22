import java.util.Arrays;

public class bitonicsortrecursive {
  private static int greatestPowerOfTwoLessThan(int n) {
    int k = 1;
    while (k < n) {
      k <<= 1;
    }
    return k >> 1;
  }

  private static void compare(int[] array, int i, int j, boolean dir) {
    boolean isGreater = array[i] > array[j];
    if (dir == isGreater) {
      int t = array[i];
      array[i] = array[j];
      array[j] = t;
    }
  }

  private static void bitonicMerge(int[] array, int lo, int n, boolean dir) {
    if (n > 1) {
      int m = greatestPowerOfTwoLessThan(n);
      for (int i = lo; i < lo + n - m; i++) {
        compare(array, i, i + m, dir);
      }
      bitonicMerge(array, lo, m, dir);
      bitonicMerge(array, lo + m, n - m, dir);
    }
  }

  private static void bitonicSort(int[] array, int lo, int n, boolean dir) {
    if (n > 1) {
      int m = n / 2;
      bitonicSort(array, lo, m, !dir);
      bitonicSort(array, lo + m, n - m, dir);
      bitonicMerge(array, lo, n, dir);
    }
  }

  public static void sort(int[] array) {
    bitonicSort(array, 0, array.length, true);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
