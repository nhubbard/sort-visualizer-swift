import java.util.Arrays;

public class recursiveshellsort {
  public static void sort(int[] arr) {
    recursiveShellSort(arr, 0, arr.length, 1);
  }

  private static void gappedInsertionSort(int[] arr, int a, int b, int gap) {
    for (int i = a + gap; i < b; i += gap) {
      int j = i;
      while (j - gap >= a && arr[j] < arr[j - gap]) {
        int temp = arr[j];
        arr[j] = arr[j - gap];
        arr[j - gap] = temp;
        j -= gap;
      }
    }
  }

  public static void recursiveShellSort(int[] arr, int start, int end, int g) {
    if (start + g <= end) {
      recursiveShellSort(arr, start, end, 3 * g);
      recursiveShellSort(arr, start + g, end, 3 * g);
      recursiveShellSort(arr, start + (2 * g), end, 3 * g);
      gappedInsertionSort(arr, start, end, g);
    }
  }

  public static void main(String[] args) {
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56
    };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
