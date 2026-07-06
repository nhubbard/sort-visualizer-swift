import java.util.Arrays;

public class stoogesort {
  public static void sort(int[] arr, int i, int j) {
    if (arr[j] < arr[i]) {
      int temp = arr[i];
      arr[i] = arr[j];
      arr[j] = temp;
    }
    if (j - i > 1) {
      int t = (j - i + 1) / 3;
      sort(arr, i, j - t);
      sort(arr, i + t, j);
      sort(arr, i, j - t);
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array, 0, array.length - 1);
    System.out.println(Arrays.toString(array));
  }
}
