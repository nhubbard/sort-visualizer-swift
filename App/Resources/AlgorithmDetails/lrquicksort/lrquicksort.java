import java.util.Arrays;

public class lrquicksort {
  public static void sort(int[] arr) {
    quickSort(arr, 0, arr.length - 1);
  }

  private static void quickSort(int[] arr, int p, int r) {
    while (p < r) {
      int pivot = arr[p + (r - p + 1) / 2];
      int i = p;
      int j = r;
      while (i <= j) {
        while (arr[i] < pivot) i++;
        while (arr[j] > pivot) j--;
        if (i <= j) {
          int temp = arr[i];
          arr[i] = arr[j];
          arr[j] = temp;
          i++;
          j--;
        }
      }
      if (j - p < r - i) {
        if (p < j) quickSort(arr, p, j);
        p = i;
      } else {
        if (i < r) quickSort(arr, i, r);
        r = j;
      }
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
