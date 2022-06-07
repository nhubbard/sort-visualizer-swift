import java.util.Arrays;

public class bubblesort {
  public static void bubbleSort(int arr[], int n) {
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
    int[] items = new int[]{35, 95, 74, 71, 72, 30, 96, 53, 9, 0};
    bubbleSort(items, items.length);
    System.out.println(Arrays.toString(items));
  }
}