import java.util.Arrays;

public class rotatemergesort {
  private static void multiSwap(int[] arr, int a, int b, int len) {
    for (int i = 0; i < len; i++) {
      int t = arr[a + i];
      arr[a + i] = arr[b + i];
      arr[b + i] = t;
    }
  }

  private static void rotate(int[] arr, int a, int m, int b) {
    int l = m - a, r = b - m;
    while (l > 0 && r > 0) {
      if (r < l) {
        multiSwap(arr, m - r, m, r);
        b -= r;
        m -= r;
        l -= r;
      } else {
        multiSwap(arr, a, m, l);
        a += l;
        m += l;
        r -= l;
      }
    }
  }

  private static int binarySearch(int[] arr, int a, int b, int value, boolean left) {
    while (a < b) {
      int mid = a + (b - a) / 2;
      boolean comp = left ? value <= arr[mid] : value < arr[mid];
      if (comp) {
        b = mid;
      } else {
        a = mid + 1;
      }
    }
    return a;
  }

  private static void rotateMerge(int[] arr, int a, int m, int b) {
    int m1, m2, m3;
    if (m - a >= b - m) {
      m1 = a + (m - a) / 2;
      int value = arr[m1];
      m2 = binarySearch(arr, m, b, value, true);
      m3 = m1 + (m2 - m);
    } else {
      m2 = m + (b - m) / 2;
      int value = arr[m2];
      m1 = binarySearch(arr, a, m, value, false);
      m3 = m2 - (m - m1);
      m2 = m2 + 1;
    }
    rotate(arr, m1, m, m2);
    if (m2 - (m3 + 1) > 0 && b - m2 > 0) {
      rotateMerge(arr, m3 + 1, m2, b);
    }
    if (m1 - a > 0 && m3 - m1 > 0) {
      rotateMerge(arr, a, m1, m3);
    }
  }

  private static void rotateMergeSort(int[] arr, int a, int b) {
    int len = b - a;
    for (int j = 1; j < len; j *= 2) {
      int i;
      for (i = a; i + 2 * j <= b; i += 2 * j) {
        rotateMerge(arr, i, i + j, i + 2 * j);
      }
      if (i + j < b) {
        rotateMerge(arr, i, i + j, b);
      }
    }
  }

  public static void sort(int[] arr) {
    rotateMergeSort(arr, 0, arr.length);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
