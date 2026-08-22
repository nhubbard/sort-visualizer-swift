import java.util.Arrays;

public class smartguesssort {
  public static boolean pairOk(int[] arr, int[] loops, int i) {
    int a = arr[loops[i]];
    int b = arr[loops[i + 1]];
    if (a < b) {
      return true;
    }
    if (a == b && loops[i] < loops[i + 1]) {
      return true;
    }
    return false;
  }

  public static int firstFailure(int[] arr, int[] loops, int n) {
    int i = n - 2;
    while (i >= 0 && pairOk(arr, loops, i)) {
      i -= 1;
    }
    return i;
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    int[] loops = new int[n];

    while (true) {
      int i = firstFailure(arr, loops, n);
      if (i < 0) {
        break;
      }
      for (int pos = 0; pos < n; pos++) {
        if (pos >= i && loops[pos] < n - 1) {
          loops[pos] += 1;
          break;
        } else {
          loops[pos] = 0;
        }
      }
    }

    int[] mapped = new int[n];
    for (int i = 0; i < n; i++) {
      mapped[i] = arr[loops[i]];
    }
    for (int i = 0; i < n; i++) {
      arr[i] = mapped[i];
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 14, 23};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
