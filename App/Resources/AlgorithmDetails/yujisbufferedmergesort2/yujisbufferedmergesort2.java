import java.util.Arrays;

public class yujisbufferedmergesort2 {
  private static int ceilLog(int n) {
    int i = 0;
    while ((1 << i) < n) {
      i++;
    }
    return i;
  }

  private static void multiSwap(int[] arr, int a, int b, int len) {
    for (int i = 0; i < len; i++) {
      int temp = arr[a + i];
      arr[a + i] = arr[b + i];
      arr[b + i] = temp;
    }
  }

  private static void insertTo(int[] arr, int a, int b) {
    int temp = arr[a];
    while (a > b) {
      a--;
      arr[a + 1] = arr[a];
    }
    arr[b] = temp;
  }

  private static int binarySearch(int[] arr, int start, int end, int value, boolean left) {
    int a = start;
    int b = end;
    while (a < b) {
      int m = a + (b - a) / 2;
      boolean comp = left ? (value <= arr[m]) : (value < arr[m]);
      if (comp) {
        b = m;
      } else {
        a = m + 1;
      }
    }
    return a;
  }

  private static void binaryInsertion(int[] arr, int a, int b) {
    int i = a + 1;
    while (i < b) {
      int value = arr[i];
      insertTo(arr, i, binarySearch(arr, a, i, value, false));
      i++;
    }
  }

  private static int merge(int[] arr, int a, int m, int b, int p) {
    int i = a;
    int j = m;
    while (i < m && j < b) {
      if (arr[i] <= arr[j]) {
        int temp = arr[p];
        arr[p] = arr[i];
        arr[i] = temp;
        p++;
        i++;
      } else {
        int temp = arr[p];
        arr[p] = arr[j];
        arr[j] = temp;
        p++;
        j++;
      }
    }
    int leftover = 0;
    while (i < m) {
      int temp = arr[p];
      arr[p] = arr[i];
      arr[i] = temp;
      p++;
      i++;
    }
    while (j < b) {
      int temp = arr[p];
      arr[p] = arr[j];
      arr[j] = temp;
      p++;
      j++;
      leftover++;
    }
    return leftover;
  }

  private static void mergeWithBufStatic(
      int[] arr, int a, int m, int b, int p, boolean useBinarySearch) {
    int i = 0;
    int j = m;
    int k = a;
    if (useBinarySearch) {
      while (i < m - a && j < b) {
        if (arr[j] < arr[p + i]) {
          int value = arr[p + i];
          int q = binarySearch(arr, j, b, value, true);
          while (j < q) {
            int temp = arr[k];
            arr[k] = arr[j];
            arr[j] = temp;
            k++;
            j++;
          }
        }
        int temp = arr[k];
        arr[k] = arr[p + i];
        arr[p + i] = temp;
        k++;
        i++;
      }
      while (i < m - a) {
        int temp = arr[k];
        arr[k] = arr[p + i];
        arr[p + i] = temp;
        k++;
        i++;
      }
    } else {
      while (i < m - a && j < b) {
        if (arr[p + i] <= arr[j]) {
          int temp = arr[k];
          arr[k] = arr[p + i];
          arr[p + i] = temp;
          k++;
          i++;
        } else {
          int temp = arr[k];
          arr[k] = arr[j];
          arr[j] = temp;
          k++;
          j++;
        }
      }
      while (i < m - a) {
        int temp = arr[k];
        arr[k] = arr[p + i];
        arr[p + i] = temp;
        k++;
        i++;
      }
    }
  }

  private static void mergeSort(int[] arr, int a, int p, int length) {
    int j = 16;
    int ceilLogValue = ceilLog(length);
    int pos = (length > 16 && (ceilLogValue & 1) == 1) ? p : a;

    int i = pos;
    while (i + 16 <= pos + length) {
      binaryInsertion(arr, i, i + 16);
      i += 16;
    }
    binaryInsertion(arr, i, pos + length);

    int nxt = pos;
    while (j < length) {
      pos = nxt;
      nxt ^= a ^ p;
      int posNext = nxt;

      i = pos;
      while (i + 2 * j <= pos + length) {
        merge(arr, i, i + j, i + 2 * j, posNext);
        i += 2 * j;
        posNext += 2 * j;
      }
      if (i + j < pos + length) {
        merge(arr, i, i + j, pos + length, posNext);
      } else {
        while (i < pos + length) {
          int temp = arr[i];
          arr[i] = arr[posNext];
          arr[posNext] = temp;
          i++;
          posNext++;
        }
      }
      j *= 2;
    }
  }

  private static void bufferedMerge(int[] arr, int a, int b) {
    if (b - a <= 16) {
      binaryInsertion(arr, a, b);
      return;
    }

    int m = (a + b + 1) / 2;
    mergeSort(arr, m, 2 * m - b, b - m);

    int n = (a + m + 1) / 2;
    int limit = (b - a) / 16;
    while (m - a > limit) {
      mergeSort(arr, 2 * n - m, n, m - n);
      mergeWithBufStatic(arr, n, m, b, 2 * n - m, (b - m) / (m - n) >= ceilLog(n - a));
      m = n;
      n = (a + m + 1) / 2;
    }

    bufferedMerge(arr, a, m);
    multiSwap(arr, a, b - (m - a), m - a);
    int s = merge(arr, m, b - (m - a), b, a);
    bufferedMerge(arr, b - (m - a) - s, b);
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n <= 1) {
      return;
    }
    bufferedMerge(arr, 0, n);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
