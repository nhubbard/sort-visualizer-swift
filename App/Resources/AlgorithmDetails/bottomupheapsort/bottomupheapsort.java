import java.util.Arrays;

public class bottomupheapsort {
  public static void siftDown(int[] arr, int i, int b) {
    int j = i;
    while (2 * j + 1 < b) {
      if (2 * j + 2 < b) {
        j = (arr[2 * j + 2] > arr[2 * j + 1]) ? 2 * j + 2 : 2 * j + 1;
      } else {
        j = 2 * j + 1;
      }
    }
    while (arr[i] > arr[j]) {
      j = (j - 1) / 2;
    }
    while (j > i) {
      int swapTemp = arr[i];
      arr[i] = arr[j];
      arr[j] = swapTemp;
      j = (j - 1) / 2;
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    for (int i = (n - 1) / 2; i >= 0; i--) {
      siftDown(arr, i, n);
    }
    for (int i = n - 1; i > 0; i--) {
      int swapTemp = arr[0];
      arr[0] = arr[i];
      arr[i] = swapTemp;
      siftDown(arr, 0, i);
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
