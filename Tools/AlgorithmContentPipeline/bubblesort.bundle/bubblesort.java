import java.util.Arrays;

public class bubblesort {
  public static void sort(int arr[]) {
    int n = arr.length;
    for (int c = 0; c < n - 1; c++) {
      for (int d = 0; d < n - c - 1; d++) {
        if (arr[d] > arr[d + 1]) {
          int swapTemp = arr[d];
          arr[d] = arr[d + 1];
          arr[d + 1] = swapTemp;
        }
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}