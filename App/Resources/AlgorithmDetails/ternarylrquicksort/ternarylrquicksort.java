import java.util.Arrays;

public class ternarylrquicksort {
  private static int compare3(int[] arr, int a, int b) {
    if (arr[a] == arr[b]) return 0;
    return arr[a] > arr[b] ? 1 : -1;
  }

  private static int selectPivot(int[] arr, int lo, int hi) {
    int mid = (lo + hi) / 2;
    int cLoMid = compare3(arr, lo, mid);
    if (cLoMid == 0) return lo;
    int cLoHi = compare3(arr, lo, hi - 1);
    int cMidHi = compare3(arr, mid, hi - 1);
    if (cLoHi == 0 || cMidHi == 0) return hi - 1;

    if (cLoMid < 0) {
      return cMidHi < 0 ? mid : (cLoHi < 0 ? hi - 1 : lo);
    } else {
      return cMidHi > 0 ? mid : (cLoHi < 0 ? lo : hi - 1);
    }
  }

  private static void quicksortTernaryLR(int[] arr, int lo, int hi) {
    if (hi <= lo) return;

    int piv = selectPivot(arr, lo, hi + 1);
    int swapTemp = arr[piv];
    arr[piv] = arr[hi];
    arr[hi] = swapTemp;
    int pivotIndex = hi;

    int i = lo, j = hi - 1;
    int p = lo, q = hi - 1;

    while (true) {
      int cmp;
      while (i <= j && (cmp = compare3(arr, i, pivotIndex)) <= 0) {
        if (cmp == 0) {
          int t = arr[i];
          arr[i] = arr[p];
          arr[p] = t;
          p++;
        }
        i++;
      }
      while (i <= j && (cmp = compare3(arr, j, pivotIndex)) >= 0) {
        if (cmp == 0) {
          int t = arr[j];
          arr[j] = arr[q];
          arr[q] = t;
          q--;
        }
        j--;
      }
      if (i > j) break;
      int t = arr[i];
      arr[i] = arr[j];
      arr[j] = t;
      i++;
      j--;
    }

    int t2 = arr[i];
    arr[i] = arr[hi];
    arr[hi] = t2;

    int numLess = i - p;
    int numGreater = q - j;

    j = i - 1;
    i = i + 1;

    int pe = lo + Math.min(p - lo, numLess);
    for (int k = lo; k < pe; k++, j--) {
      int t3 = arr[k];
      arr[k] = arr[j];
      arr[j] = t3;
    }

    int qe = hi - 1 - Math.min(hi - 1 - q, numGreater - 1);
    for (int k = hi - 1; k > qe; k--, i++) {
      int t4 = arr[i];
      arr[i] = arr[k];
      arr[k] = t4;
    }

    quicksortTernaryLR(arr, lo, lo + numLess - 1);
    quicksortTernaryLR(arr, hi - numGreater + 1, hi);
  }

  public static void sort(int[] arr) {
    quicksortTernaryLR(arr, 0, arr.length - 1);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
