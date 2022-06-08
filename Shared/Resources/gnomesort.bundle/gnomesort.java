import java.util.Arrays;

public class gnomesort {
  public static void sort(int[] arr) {
    int n = arr.length;
    int index = 0;
    while (index < n) {
      if (index == 0) {
        index++;
      }
      if (arr[index] >= arr[index - 1]) {
        index++;
      } else {
        int swapTemp = arr[index];
        arr[index] = arr[index - 1];
        arr[index - 1] = swapTemp;
        index--;
      }
    }
  }

  public static void main(String[] args) {
    int[] items = new int[]{35, 95, 74, 71, 72, 30, 96, 53, 9, 0};
    sort(items);
    System.out.println(Arrays.toString(items));
  }
}