import java.util.ArrayDeque;
import java.util.Arrays;
import java.util.Deque;

public class binaryquicksortiterative {
  private static int mostSignificantBit(int value) {
    if (value == 0) return -1;
    int bit = 0;
    while ((value >> (bit + 1)) != 0) bit++;
    return bit;
  }

  private static int partition(int[] arr, int p, int r, int bit) {
    int i = p - 1;
    int j = r + 1;
    while (true) {
      do {
        i++;
      } while (i <= r && ((arr[i] >> bit) & 1) == 0);
      do {
        j--;
      } while (j >= p && ((arr[j] >> bit) & 1) == 1);
      if (i < j) {
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
      } else {
        return j;
      }
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    int maxValue = arr[0];
    for (int i = 1; i < n; i++) {
      if (arr[i] > maxValue) maxValue = arr[i];
    }
    int bit = mostSignificantBit(maxValue);

    Deque<int[]> tasks = new ArrayDeque<>();
    tasks.addLast(new int[]{0, n - 1, bit});

    while (!tasks.isEmpty()) {
      int[] t = tasks.removeFirst();
      int p = t[0];
      int r = t[1];
      int b = t[2];
      if (p < r && b >= 0) {
        int q = partition(arr, p, r, b);
        tasks.addLast(new int[]{p, q, b - 1});
        tasks.addLast(new int[]{q + 1, r, b - 1});
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
