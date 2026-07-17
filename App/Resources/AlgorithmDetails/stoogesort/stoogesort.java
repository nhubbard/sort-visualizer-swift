import java.util.Arrays;

public class stoogesort {
  private static void stoogeSort(int[] arr, int i, int j) {
    if (arr[j] < arr[i]) {
      int temp = arr[i];
      arr[i] = arr[j];
      arr[j] = temp;
    }
    if (j - i > 1) {
      int t = (j - i + 1) / 3;
      stoogeSort(arr, i, j - t);
      stoogeSort(arr, i + t, j);
      stoogeSort(arr, i, j - t);
    }
  }

  public static void sort(int[] arr) {
    stoogeSort(arr, 0, arr.length - 1);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
