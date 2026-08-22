import java.util.Arrays;

public class classictreesort {
  private static int idx;

  private static void traverse(int[] array, int[] temp, int[] lower, int[] upper, int r) {
    if (lower[r] != 0) {
      traverse(array, temp, lower, upper, lower[r]);
    }
    temp[idx++] = array[r];
    if (upper[r] != 0) {
      traverse(array, temp, lower, upper, upper[r]);
    }
  }

  public static void sort(int[] array) {
    int n = array.length;
    if (n <= 1) {
      return;
    }
    int[] lower = new int[n];
    int[] upper = new int[n];

    for (int i = 1; i < n; i++) {
      int c = 0;
      while (true) {
        int[] next = array[i] < array[c] ? lower : upper;
        if (next[c] == 0) {
          next[c] = i;
          break;
        } else {
          c = next[c];
        }
      }
    }

    int[] temp = new int[n];
    idx = 0;
    traverse(array, temp, lower, upper, 0);
    System.arraycopy(temp, 0, array, 0, n);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
