import java.util.Arrays;

public class circlesortiterative {
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

  public static void sort(int[] arr) {
    int end = arr.length;
    if (end <= 1) {
      return;
    }
    int n = 1;
    while (n < end) {
      n <<= 1;
    }

    int numberOfSwaps = 1;
    while (numberOfSwaps != 0) {
      numberOfSwaps = circleSortRoutine(arr, n, end);
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
