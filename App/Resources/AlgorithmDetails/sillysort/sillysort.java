import java.util.Arrays;

public class sillysort {
  private static void sillySort(int[] arr, int i, int j) {
    if (i < j) {
      int m = i + (j - i) / 2;
      sillySort(arr, i, m);
      sillySort(arr, m + 1, j);
      if (arr[i] >= arr[m + 1]) {
        int temp = arr[i];
        arr[i] = arr[m + 1];
        arr[m + 1] = temp;
      }
      sillySort(arr, i + 1, j);
    }
  }

  public static void sort(int[] arr) {
    sillySort(arr, 0, arr.length - 1);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
