import java.util.Arrays;

public class llquicksort {
  private static int partition(int[] arr, int lo, int hi) {
    int pivot = arr[hi];
    int i = lo;
    for (int j = lo; j < hi; j++) {
      if (arr[j] < pivot) {
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
        i++;
      }
    }
    int temp = arr[i];
    arr[i] = arr[hi];
    arr[hi] = temp;
    return i;
  }

  public static void quickSort(int[] arr, int lo, int hi) {
    if (lo < hi) {
      int p = partition(arr, lo, hi);
      quickSort(arr, lo, p - 1);
      quickSort(arr, p + 1, hi);
    }
  }

  public static void sort(int[] arr) {
    quickSort(arr, 0, arr.length - 1);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
