import java.util.Arrays;

public class weakheapsort {
  public static void merge(int[] arr, boolean[] flags, int i, int j) {
    if (arr[i] < arr[j]) {
      flags[j] = !flags[j];
      int temp = arr[i];
      arr[i] = arr[j];
      arr[j] = temp;
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    boolean[] flags = new boolean[n];

    for (int i = n - 1; i > 0; i--) {
      int j = i;
      while ((j & 1) == (flags[j >> 1] ? 1 : 0)) {
        j >>= 1;
      }
      int gparent = j >> 1;
      merge(arr, flags, gparent, i);
    }

    for (int i = n - 1; i > 1; i--) {
      int temp = arr[0];
      arr[0] = arr[i];
      arr[i] = temp;
      int x = 1;
      while (true) {
        int y = 2 * x + (flags[x] ? 1 : 0);
        if (y >= i) {
          break;
        }
        x = y;
      }
      while (x > 0) {
        merge(arr, flags, 0, x);
        x >>= 1;
      }
    }
    int temp = arr[0];
    arr[0] = arr[1];
    arr[1] = temp;
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
