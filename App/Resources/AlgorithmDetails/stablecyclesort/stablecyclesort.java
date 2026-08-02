import java.util.Arrays;

public class stablecyclesort {
  private static int destination(int[] arr, boolean[] flagged, int a, int b1, int b) {
    int heldValue = arr[a];
    int d = a;
    int e = 0;
    for (int i = a + 1; i < b; i++) {
      if (arr[i] < heldValue) {
        d++;
      } else if (i < b1 && !flagged[i] && arr[i] == heldValue) {
        e++;
      }
    }
    while (flagged[d] || e > 0) {
      if (!flagged[d]) {
        e--;
      }
      d++;
    }
    return d;
  }

  private static void stableCycleSort(int[] arr) {
    int n = arr.length;
    if (n <= 1) {
      return;
    }
    boolean[] flagged = new boolean[n];
    for (int i = 0; i < n - 1; i++) {
      if (flagged[i]) {
        continue;
      }
      int j = i;
      do {
        int k = destination(arr, flagged, i, j, n);
        int temp = arr[i];
        arr[i] = arr[k];
        arr[k] = temp;
        flagged[k] = true;
        j = k;
      } while (j != i);
    }
  }

  public static void sort(int[] arr) {
    stableCycleSort(arr);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
