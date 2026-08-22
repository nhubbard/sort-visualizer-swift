import java.util.Arrays;

public class introcirclesortiterative {
  private static int circleSortRoutine(int[] arr, int length, int end) {
    int swapCount = 0;
    for (int gap = length / 2; gap > 0; gap /= 2) {
      for (int start = 0; start + gap < end; start += 2 * gap) {
        int low = start;
        int high = start + 2 * gap - 1;
        while (low < high) {
          if (high < end && arr[low] > arr[high]) {
            int temp = arr[low];
            arr[low] = arr[high];
            arr[high] = temp;
            swapCount++;
          }
          low++;
          high--;
        }
      }
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
      if (circleSortRoutine(arr, n, end) == 0) {
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
