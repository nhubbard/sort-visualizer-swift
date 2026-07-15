import java.util.Arrays;

public class randomguesssort {
  public static void sort(int arr[]) {
    int n = arr.length;
    int[] loops = new int[n];
    while (true) {
      boolean isSorted = true;
      for (int i = 0; i < n - 1; i++) {
        int a = arr[loops[i]];
        int b = arr[loops[i + 1]];
        if (a < b || (a == b && loops[i] < loops[i + 1])) {
          continue;
        }
        isSorted = false;
        break;
      }
      if (isSorted) {
        break;
      }
      for (int pos = 0; pos < n; pos++) {
        loops[pos] = (int)(Math.random() * n);
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
    int[] array = new int[]{0, 39, 21, 62, 14};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
