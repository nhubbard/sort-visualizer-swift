import java.util.Arrays;

public class circlesortrecursive {
  private static int nextPowerOfTwo(int n) {
    int k = 1;
    while (k < n) {
      k <<= 1;
    }
    return k;
  }

  private static int circleSortRoutine(int[] array, int lo, int hi, int end) {
    if (lo == hi) {
      return 0;
    }
    int low = lo;
    int high = hi;
    int mid = (hi - lo) / 2;
    int swaps = 0;
    while (lo < hi) {
      if (hi < end && array[lo] > array[hi]) {
        int t = array[lo];
        array[lo] = array[hi];
        array[hi] = t;
        swaps++;
      }
      lo++;
      hi--;
    }
    swaps += circleSortRoutine(array, low, low + mid, end);
    if (low + mid + 1 < end) {
      swaps += circleSortRoutine(array, low + mid + 1, high, end);
    }
    return swaps;
  }

  public static void sort(int[] array) {
    int end = array.length;
    if (end == 0) {
      return;
    }
    int paddedLength = nextPowerOfTwo(end);
    int swaps;
    do {
      swaps = circleSortRoutine(array, 0, paddedLength - 1, end);
    } while (swaps != 0);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
