import java.util.Arrays;

public class ternaryllquicksort {
  public static int compare3(int[] arr, int a, int b) {
    if (arr[a] == arr[b]) return 0;
    return arr[a] > arr[b] ? 1 : -1;
  }

  public static int selectPivot(int[] arr, int lo, int hi) {
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

  public static int[] partitionTernaryLL(int[] arr, int lo, int hi) {
    int p = selectPivot(arr, lo, hi);
    int tmp = arr[p];
    arr[p] = arr[hi - 1];
    arr[hi - 1] = tmp;
    int pivotIndex = hi - 1;

    int i = lo;
    int k = hi - 1;

    for (int j = lo; j < k; j++) {
      int cmp = compare3(arr, j, pivotIndex);
      if (cmp == 0) {
        k--;
        int t = arr[k];
        arr[k] = arr[j];
        arr[j] = t;
        j--;
      } else if (cmp < 0) {
        int t = arr[i];
        arr[i] = arr[j];
        arr[j] = t;
        i++;
      }
    }

    for (int s = 0; s < hi - k; s++) {
      int t = arr[i + s];
      arr[i + s] = arr[hi - 1 - s];
      arr[hi - 1 - s] = t;
    }

    return new int[]{i, i + (hi - k)};
  }

  public static void quicksortTernaryLL(int[] arr, int lo, int hi) {
    if (lo + 1 < hi) {
      int[] mid = partitionTernaryLL(arr, lo, hi);
      quicksortTernaryLL(arr, lo, mid[0]);
      quicksortTernaryLL(arr, mid[1], hi);
    }
  }

  public static void sort(int[] arr) {
    quicksortTernaryLL(arr, 0, arr.length);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
