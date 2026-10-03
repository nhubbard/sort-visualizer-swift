import java.util.Arrays;

public class synchronoussqrtsort {
  private static int blockSize = 1;

  public static void sort(int[] arr) {
    blockSize = 1;
    while (blockSize * blockSize < arr.length) {
      blockSize *= 2;
    }
    synchronousSort(arr, 0, arr.length);
  }

  private static void multiSwap(int[] arr, int a, int b, int len) {
    for (int i = 0; i < len; i++) {
      int t = arr[a + i];
      arr[a + i] = arr[b + i];
      arr[b + i] = t;
    }
  }

  private static void rotate(int[] arr, int a, int m, int b) {
    int l = m - a;
    int r = b - m;
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

  private static void synchronousMerge(int[] arr, int a, int m, int b) {
    if (m - a <= blockSize && b - m <= blockSize) {
      int[] temp = Arrays.copyOfRange(arr, a, b);
      int i = 0;
      int j = m - a;
      for (int k = a; k < b; k++) {
        if (i < m - a && (j == b - a || temp[i] <= temp[j])) {
          arr[k] = temp[i++];
        } else {
          arr[k] = temp[j++];
        }
      }
      return;
    }
    int m1;
    int m2;
    int m3;
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
      synchronousMerge(arr, m3 + 1, m2, b);
    }
    if (m1 - a > 0 && m3 - m1 > 0) {
      synchronousMerge(arr, a, m1, m3);
    }
  }

  private static void synchronousSort(int[] arr, int a, int b) {
    int len = b - a;
    for (int start = a; start < b; start += 16) {
      int end = Math.min(start + 16, b);
      for (int i = start + 1; i < end; i++) {
        int value = arr[i];
        int j = i;
        while (j > start && arr[j - 1] > value) {
          arr[j] = arr[j - 1];
          j--;
        }
        arr[j] = value;
      }
    }
    for (int j = 16; j < len; j *= 2) {
      int i;
      for (i = a; i + 2 * j <= b; i += 2 * j) {
        synchronousMerge(arr, i, i + j, i + 2 * j);
      }
      if (i + j < b) {
        synchronousMerge(arr, i, i + j, b);
      }
    }
  }

  public static void main(String[] args) {
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56
    };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
