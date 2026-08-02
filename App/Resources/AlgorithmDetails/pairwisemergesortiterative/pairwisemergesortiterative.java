import java.util.Arrays;

public class pairwisemergesortiterative {
  private static int end;

  private static void compSwap(int[] arr, int a, int b) {
    if (b < end && arr[a] > arr[b]) {
      int temp = arr[a];
      arr[a] = arr[b];
      arr[b] = temp;
    }
  }

  public static void sort(int[] arr) {
    int length = arr.length;
    end = length;

    int n = 1;
    while (n < length) {
      n <<= 1;
    }

    int k = n >> 1;
    while (k > 0) {
      int j = 0;
      while (j < length) {
        for (int i = 0; i < k; i++) {
          compSwap(arr, j + i, j + k + i);
        }
        j += k << 1;
      }
      k >>= 1;
    }

    k = 2;
    while (k < n) {
      int m = k >> 1;
      while (m > 0) {
        int j = 0;
        while (j < length) {
          int p = m;
          while (p < ((k - m) << 1)) {
            for (int i = 0; i < m; i++) {
              compSwap(arr, j + p + i, j + p + m + i);
            }
            p += m << 1;
          }
          j += k << 1;
        }
        m >>= 1;
      }
      k <<= 1;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
