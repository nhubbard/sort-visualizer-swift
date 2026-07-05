import java.util.Arrays;

public class shakersort {
  public static void sort(int[] arr) {
    int n = arr.length;
    boolean swapped = true;
    int start = 0;
    int end = n - 1;
    while (swapped) {
      swapped = false;
      for (int i = start; i < end; i++) {
        if (arr[i] > arr[i + 1]) {
          int swapTemp = arr[i];
          arr[i] = arr[i + 1];
          arr[i + 1] = swapTemp;
          swapped = true;
        }
      }
      if (!swapped) {
        break;
      }
      swapped = false;
      end--;
      for (int i = end - 1; i >= start; i--) {
        if (arr[i] > arr[i + 1]) {
          int swapTemp = arr[i];
          arr[i] = arr[i + 1];
          arr[i + 1] = swapTemp;
          swapped = true;
        }
      }
      start++;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}