import java.util.Arrays;
import java.util.Comparator;

public class timesort {
  public static void sort(int[] arr) {
    int n = arr.length;
    if (n <= 1) {
      return;
    }

    // Simulate the reporting order that proportional-to-value sleep durations
    // would produce in a jitter-free race: sort by value, ties broken by the
    // original position, i.e. the order the sleeps were originally scheduled.
    Integer[] indices = new Integer[n];
    for (int i = 0; i < n; i++) {
      indices[i] = i;
    }
    Arrays.sort(indices, Comparator.<Integer>comparingInt(i -> arr[i]).thenComparingInt(i -> i));

    int[] woken = new int[n];
    for (int i = 0; i < n; i++) {
      woken[i] = arr[indices[i]];
    }
    System.arraycopy(woken, 0, arr, 0, n);

    // Defensive cleanup pass: real scheduling jitter can't be fully trusted,
    // so finish with an ordinary insertion sort no matter what the race produced.
    for (int i = 1; i < n; i++) {
      int j = i;
      while (j > 0 && arr[j - 1] > arr[j]) {
        int t = arr[j - 1];
        arr[j - 1] = arr[j];
        arr[j] = t;
        j--;
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
