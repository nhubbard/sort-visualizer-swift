import java.util.Arrays;

public class introcirclesortrecursive {
  private static int circleSortRoutine(int[] arr, int lo, int hi, int end) {
    if (lo == hi) {
      return 0;
    }
    int low = lo;
    int high = hi;
    int mid = (hi - lo) / 2;
    int swapCount = 0;
    while (lo < hi) {
      if (hi < end && arr[lo] > arr[hi]) {
        int temp = arr[lo];
        arr[lo] = arr[hi];
        arr[hi] = temp;
        swapCount++;
      }
      lo++;
      hi--;
    }
    swapCount += circleSortRoutine(arr, low, low + mid, end);
    if (low + mid + 1 < end) {
      swapCount += circleSortRoutine(arr, low + mid + 1, high, end);
    }
    return swapCount;
  }

  private static void binaryInsertionSort(int[] arr, int end) {
    for (int i = 1; i < end; i++) {
      int value = arr[i];
      int lo = 0;
      int hi = i;
      while (lo < hi) {
        int mid = lo + (hi - lo) / 2;
        if (value < arr[mid]) {
          hi = mid;
        } else {
          lo = mid + 1;
        }
      }
      int j = i;
      while (j > lo) {
        arr[j] = arr[j - 1];
        j--;
      }
      arr[lo] = value;
    }
  }

  public static void sort(int[] arr) {
    int end = arr.length;
    if (end <= 1) {
      return;
    }
    int n = 1;
    int threshold = 0;
    while (n < end) {
      n <<= 1;
      threshold++;
    }
    threshold /= 2;

    int iterations = 0;
    while (true) {
      iterations++;
      if (iterations >= threshold) {
        binaryInsertionSort(arr, end);
        return;
      }
      if (circleSortRoutine(arr, 0, n - 1, end) == 0) {
        return;
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
