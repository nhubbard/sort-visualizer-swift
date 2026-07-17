import java.util.Arrays;

public class blockswapmergesort {
  private static void multiSwap(int[] arr, int a, int b, int len) {
    for (int i = 0; i < len; i++) {
      int t = arr[a + i];
      arr[a + i] = arr[b + i];
      arr[b + i] = t;
    }
  }

  private static int binarySearchMid(int[] arr, int start, int mid, int end) {
    int a = 0;
    int b = Math.min(mid - start, end - mid);
    int m = a + (b - a) / 2;
    while (b > a) {
      if (arr[mid - m - 1] > arr[mid + m]) {
        a = m + 1;
      } else {
        b = m;
      }
      m = a + (b - a) / 2;
    }
    return m;
  }

  private static void multiSwapMerge(int[] arr, int start, int mid, int end) {
    int m = binarySearchMid(arr, start, mid, end);
    while (m > 0) {
      multiSwap(arr, mid - m, mid, m);
      multiSwapMerge(arr, mid, mid + m, end);
      end = mid;
      mid -= m;
      m = binarySearchMid(arr, start, mid, end);
    }
  }

  private static void multiSwapMergeSort(int[] arr, int a, int b) {
    int len = b - a;
    for (int j = 1; j < len; j *= 2) {
      int i;
      for (i = a; i + 2 * j <= b; i += 2 * j) {
        multiSwapMerge(arr, i, i + j, i + 2 * j);
      }
      if (i + j < b) {
        multiSwapMerge(arr, i, i + j, b);
      }
    }
  }

  public static void sort(int[] arr) {
    multiSwapMergeSort(arr, 0, arr.length);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
