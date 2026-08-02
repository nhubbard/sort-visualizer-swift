import java.util.Arrays;

public class diamondsortiterative {
  private static void compSwap(int[] arr, int a, int b) {
    if (arr[a] > arr[b]) {
      int temp = arr[a];
      arr[a] = arr[b];
      arr[b] = temp;
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    int p = 1;
    while (p < n) {
      p *= 2;
    }

    int m = 4;
    while (m <= p) {
      for (int k = 0; k < m / 2; k++) {
        int cnt = k <= m / 4 ? k : m / 2 - k;
        int j = 0;
        while (j < n) {
          if (j + cnt + 1 < n) {
            int i = j + cnt;
            while (i + 1 < Math.min(n, j + m - cnt)) {
              compSwap(arr, i, i + 1);
              i += 2;
            }
          }
          j += m;
        }
      }
      m *= 2;
    }
    m /= 2;
    for (int k = 0; k <= m / 2; k++) {
      int i = k;
      while (i + 1 < Math.min(n, m - k)) {
        compSwap(arr, i, i + 1);
        i += 2;
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
