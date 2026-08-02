import java.util.Arrays;

public class pairwisemergesortrecursive {
  private static int end;

  private static void compSwap(int[] arr, int a, int b) {
    if (b < end && arr[a] > arr[b]) {
      int temp = arr[a];
      arr[a] = arr[b];
      arr[b] = temp;
    }
  }

  private static void pairwiseMerge(int[] arr, int a, int b) {
    int m = (a + b) / 2;
    int m1 = (a + m) / 2;
    int g = m - m1;

    for (int i = 0; i < m - m1; i++) {
      int j = m1;
      int k = g;
      while (k > 0) {
        compSwap(arr, j + i, j + i + k);
        k >>= 1;
        j -= (k - (i & k));
      }
    }
    if (b - a > 4) {
      pairwiseMerge(arr, m, b);
    }
  }

  private static void pairwiseMergeSort(int[] arr, int a, int b) {
    int m = (a + b) / 2;
    int i = a;
    int j = m;
    while (i < m) {
      compSwap(arr, i, j);
      i++;
      j++;
    }
    if (b - a > 2) {
      pairwiseMergeSort(arr, a, m);
      pairwiseMergeSort(arr, m, b);
      pairwiseMerge(arr, a, b);
    }
  }

  public static void sort(int[] arr) {
    int length = arr.length;
    end = length;

    int n = 1;
    while (n < length) {
      n <<= 1;
    }

    pairwiseMergeSort(arr, 0, n);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
