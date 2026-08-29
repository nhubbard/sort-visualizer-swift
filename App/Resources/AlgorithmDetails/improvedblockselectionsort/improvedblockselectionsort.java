import java.util.Arrays;

public class improvedblockselectionsort {
  private static int blockRoot(int n) {
    int i = 1;
    while (i * i < n) {
      i *= 2;
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

  private static int selectRange(int[] arr, int start, int end, int bLen) {
    int minIndex = start;
    int a = start + bLen;
    while (a < end) {
      if (arr[a] < arr[minIndex]) {
        minIndex = a;
      } else if (arr[a] == arr[minIndex] && arr[a + bLen - 1] < arr[minIndex + bLen - 1]) {
        minIndex = a;
      }
      a += bLen;
    }
    return minIndex;
  }

  private static void blockSelect(int[] arr, int a, int m, int b, int bLen) {
    int k = a;
    int j = m;
    while (k < m && arr[k] <= arr[m]) {
      k += bLen;
    }
    if (k == m) {
      return;
    }

    int i = m;
    multiSwap(arr, k, j, bLen);
    k += bLen;
    j += bLen;

    while (k < j && j < b) {
      if (arr[i] <= arr[j]) {
        if (k != i) {
          multiSwap(arr, k, i, bLen);
        }
        k += bLen;
        i = selectRange(arr, Math.max(m, k), j, bLen);
      } else {
        if (i == k) {
          i = j;
        }
        if (k != j) {
          multiSwap(arr, k, j, bLen);
        }
        k += bLen;
        j += bLen;
      }
    }

    while (k < j) {
      i = selectRange(arr, k, b, bLen);
      if (k != i) {
        multiSwap(arr, k, i, bLen);
      }
      k += bLen;
    }
  }

  private static int inPlaceMerge(int[] arr, int a, int m, int b) {
    int i = a;
    int j = m;
    while (i < j && j < b) {
      if (arr[i] > arr[j]) {
        int k = j + 1;
        while (k < b && arr[i] > arr[k]) {
          k++;
        }
        rotate(arr, i, j, k);
        i += k - j;
        j = k;
      } else {
        i++;
      }
    }
    return i;
  }

  private static void inPlaceMergeBW(int[] arr, int a, int m, int b) {
    int i = m - 1;
    int j = b - 1;
    while (j > i && i >= a) {
      if (arr[i] > arr[j]) {
        int k = i - 1;
        while (k >= a && arr[k] > arr[j]) {
          k--;
        }
        rotate(arr, k + 1, i + 1, j + 1);
        j -= i - k;
        i = k;
      } else {
        j--;
      }
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n <= 1) {
      return;
    }
    int j = 1;
    while (j < n) {
      int bLen = blockRoot(j);
      int runLength = j;
      int b = n - n % bLen;

      while (runLength > 16) {
        int i = 0;
        while (i + j < b) {
          int k = i;
          while (k + runLength < Math.min(i + 2 * j, b)) {
            blockSelect(arr, k, k + runLength, Math.min(k + 2 * runLength, b), bLen);
            k += runLength;
          }
          i += 2 * j;
        }
        runLength = bLen;
        bLen = blockRoot(bLen);
      }

      int i = 0;
      while (i + j < b) {
        int k = i;
        int f = i;
        while (k + runLength < Math.min(i + 2 * j, b)) {
          f = inPlaceMerge(arr, f, k + runLength, Math.min(k + 2 * runLength, b));
          k += runLength;
        }
        i += 2 * j;
      }

      inPlaceMergeBW(arr, n - n % (2 * j), b, n);
      j *= 2;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
