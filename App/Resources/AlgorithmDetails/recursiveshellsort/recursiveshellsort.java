import java.util.Arrays;

public class recursiveshellsort {
  private static void gappedInsertionSort(int arr[], int a, int b, int gap) {
    for (int i = a + gap; i < b; i += gap) {
      int key = arr[i];
      int j = i - gap;
      while (j >= a && key < arr[j]) {
        arr[j + gap] = arr[j];
        j -= gap;
      }
      arr[j + gap] = key;
    }
  }

  public static void recursiveShellSort(int arr[], int start, int end, int g) {
    if (start + g <= end) {
      recursiveShellSort(arr, start, end, 3 * g);
      recursiveShellSort(arr, start + g, end, 3 * g);
      recursiveShellSort(arr, start + (2 * g), end, 3 * g);
      gappedInsertionSort(arr, start, end, g);
    }
  }

  public static void sort(int arr[]) {
    recursiveShellSort(arr, 0, arr.length, 1);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
