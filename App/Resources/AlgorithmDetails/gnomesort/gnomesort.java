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
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}