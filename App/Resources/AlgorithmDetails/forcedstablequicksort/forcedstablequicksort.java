import java.util.Arrays;

public class forcedstablequicksort {
  private static boolean stableComp(int[] arr, int[] key, int a, int b) {
    if (arr[a] > arr[b]) return true;
    if (arr[a] == arr[b]) return key[a] > key[b];
    return false;
  }

  private static void stableSwap(int[] arr, int[] key, int a, int b) {
    int t = arr[a];
    arr[a] = arr[b];
    arr[b] = t;
    int tk = key[a];
    key[a] = key[b];
    key[b] = tk;
  }

  private static void medianOfThree(int[] arr, int[] key, int a, int b) {
    int m = a + (b - 1 - a) / 2;
    if (stableComp(arr, key, a, m)) stableSwap(arr, key, a, m);
    if (stableComp(arr, key, m, b - 1)) {
      stableSwap(arr, key, m, b - 1);
      if (stableComp(arr, key, a, m)) return;
    }
    stableSwap(arr, key, a, m);
  }

  private static int partition(int[] arr, int[] key, int a, int b, int p) {
    int i = a - 1;
    int j = b;
    while (true) {
      do {
        i++;
      } while (i < j && !stableComp(arr, key, i, p));
      do {
        j--;
      } while (j >= i && stableComp(arr, key, j, p));
      if (i < j) {
        stableSwap(arr, key, i, j);
      } else {
        return j;
      }
    }
  }

  private static void quickSort(int[] arr, int[] key, int a, int b) {
    if (b - a < 3) {
      if (b - a == 2 && stableComp(arr, key, a, a + 1)) stableSwap(arr, key, a, a + 1);
      return;
    }
    medianOfThree(arr, key, a, b);
    int p = partition(arr, key, a + 1, b, a);
    stableSwap(arr, key, a, p);
    quickSort(arr, key, a, p);
    quickSort(arr, key, p + 1, b);
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    int[] key = new int[n];
    for (int i = 0; i < n; i++) key[i] = i;
    quickSort(arr, key, 0, n);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}