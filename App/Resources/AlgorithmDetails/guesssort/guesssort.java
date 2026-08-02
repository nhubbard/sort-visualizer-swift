import java.util.Arrays;

public class guesssort {
  public static boolean isValid(int[] arr, int[] loops, int n) {
    int total = 0;
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (loops[i] == loops[j]) {
          total += 1;
        }
      }
    }
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (i < j && arr[loops[i]] > arr[loops[j]]) {
          total += 1;
        } else if (i > j && arr[loops[i]] < arr[loops[j]]) {
          total += 1;
        }
      }
    }
    return total == n;
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    int[] loops = new int[n];
    int[] indexes = new int[n];

    while (true) {
      if (isValid(arr, loops, n)) {
        System.arraycopy(loops, 0, indexes, 0, n);
      }
      int pos = 0;
      while (pos < n) {
        if (loops[pos] < n - 1) {
          loops[pos] += 1;
          break;
        } else {
          loops[pos] = 0;
          pos += 1;
        }
      }
      if (pos == n) {
        break;
      }
    }

    int[] original = arr.clone();
    for (int i = 0; i < n; i++) {
      arr[i] = original[indexes[i]];
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 14};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
