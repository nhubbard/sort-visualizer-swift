import java.util.Arrays;

public class foldsort {
  private static int end;

  private static void compSwap(int[] arr, int a, int b) {
    if (b < end && arr[a] > arr[b]) {
      int temp = arr[a];
      arr[a] = arr[b];
      arr[b] = temp;
    }
  }

  private static void halver(int[] arr, int low, int high) {
    while (low < high) {
      compSwap(arr, low, high);
      low++;
      high--;
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    end = n;
    int ceilLog = 1;
    while ((1 << ceilLog) < n) {
      ceilLog++;
    }
    int size2 = 1 << ceilLog;

    int k = size2 >> 1;
    while (k > 0) {
      int i = size2;
      while (i >= k) {
        int j = 0;
        while (j < end) {
          halver(arr, j, j + i - 1);
          j += i;
        }
        i >>= 1;
      }
      k >>= 1;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
