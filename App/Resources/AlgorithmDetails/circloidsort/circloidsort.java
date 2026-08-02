import java.util.Arrays;

public class circloidsort {
  private static boolean circle(int[] array, int left, int right) {
    int a = left;
    int b = right;
    boolean swapped = false;
    while (a < b) {
      if (array[a] > array[b]) {
        int t = array[a];
        array[a] = array[b];
        array[b] = t;
        swapped = true;
      }
      a++;
      b--;
      if (a == b) {
        b++;
      }
    }
    return swapped;
  }

  private static boolean circlePass(int[] array, int left, int right) {
    if (left >= right) {
      return false;
    }
    int mid = (left + right) / 2;
    boolean l = circlePass(array, left, mid);
    boolean r = circlePass(array, mid + 1, right);
    return circle(array, left, right) || l || r;
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n <= 1) {
      return;
    }
    while (circlePass(arr, 0, n - 1)) {
      // repeat until a full sweep makes no swaps
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
