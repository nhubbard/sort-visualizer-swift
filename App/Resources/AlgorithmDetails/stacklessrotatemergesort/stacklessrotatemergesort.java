import java.util.Arrays;

public class stacklessrotatemergesort {
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

  /**
   * Selects the c smallest combined elements of the two already-sorted runs arr[a, m) and arr[m, b)
   * into the front half via a single rotation. Uses a merge-path (co-rank) binary search over
   * whichever run is shorter: it looks for the split count r such that taking r elements from the
   * tail of one run and (c - r) from the head of the other yields exactly the c smallest values in
   * order, rather than searching for a value directly.
   */
  private static void partitionMerge(int[] arr, int a, int m, int b, int c) {
    int lenA = m - a;
    int lenB = b - m;
    if (lenA < 1 || lenB < 1) {
      return;
    }

    if (lenB < lenA) {
      int cc = (lenA + lenB) - c;
      int r1 = Math.max(0, cc - lenA);
      int r2 = Math.min(cc, lenB);
      while (r1 < r2) {
        int ml = r1 + (r2 - r1) / 2;
        if (arr[m - (cc - ml)] > arr[b - ml - 1]) {
          r2 = ml;
        } else {
          r1 = ml + 1;
        }
      }
      rotate(arr, m - (cc - r1), m, b - r1);
    } else {
      int r1 = Math.max(0, c - lenB);
      int r2 = Math.min(c, lenA);
      while (r1 < r2) {
        int ml = r1 + (r2 - r1) / 2;
        if (arr[a + ml] > arr[m + (c - ml) - 1]) {
          r2 = ml;
        } else {
          r1 = ml + 1;
        }
      }
      rotate(arr, a + r1, m, m + (c - r1));
    }
  }

  /**
   * Finds the first place inside arr[a, b) where ascending order breaks, then partition-merges the
   * sorted piece before it with the sorted piece after it. A no-op if arr[a, b) is already one
   * ascending run.
   */
  private static void rotateMerge(int[] arr, int a, int b, int c) {
    int i = a + 1;
    while (i < b && arr[i - 1] <= arr[i]) {
      i++;
    }
    if (i < b) {
      partitionMerge(arr, a, i, b, c);
    }
  }

  private static void rotatePartitionMergeSort(int[] arr, int n) {
    if (n < 2) {
      return;
    }

    for (int i = 1; i < n; i += 2) {
      if (arr[i - 1] > arr[i]) {
        int t = arr[i - 1];
        arr[i - 1] = arr[i];
        arr[i] = t;
      }
    }

    for (int j = 2; j < n; j *= 2) {
      int b1 = 0;
      int blockStart = 0;
      while (blockStart + j < n) {
        b1 = Math.min(blockStart + 2 * j, n);
        partitionMerge(arr, blockStart, blockStart + j, b1, j);
        blockStart += 2 * j;
      }

      for (int k = j / 2; k > 1; k /= 2) {
        int seamStart = 0;
        while (seamStart + k < b1) {
          int seamEnd = Math.min(seamStart + 2 * k, n);
          rotateMerge(arr, seamStart, seamEnd, k);
          seamStart += 2 * k;
        }
      }

      for (int m = 1; m < b1; m += 2) {
        if (arr[m - 1] > arr[m]) {
          int t = arr[m - 1];
          arr[m - 1] = arr[m];
          arr[m] = t;
        }
      }
    }
  }

  public static void sort(int[] arr) {
    rotatePartitionMergeSort(arr, arr.length);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
