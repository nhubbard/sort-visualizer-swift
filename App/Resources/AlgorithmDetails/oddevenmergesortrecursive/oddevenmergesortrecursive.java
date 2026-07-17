import java.util.Arrays;

public class oddevenmergesortrecursive {
  private static void oddEvenMergeCompare(int[] arr, int i, int j) {
    if (arr[i] > arr[j]) {
      int temp = arr[i];
      arr[i] = arr[j];
      arr[j] = temp;
    }
  }

  // lo is the starting position, m2 is the halfway point, n is the length of
  // the piece being merged, and r is the distance of the elements compared.
  private static void oddEvenMerge(int[] arr, int lo, int m2, int n, int r) {
    int m = r * 2;
    if (m < n) {
      if ((n / r) % 2 != 0) {
        oddEvenMerge(arr, lo, (m2 + 1) / 2, n + r, m);     // even subsequence
        oddEvenMerge(arr, lo + r, m2 / 2, n - r, m);       // odd subsequence
      } else {
        oddEvenMerge(arr, lo, (m2 + 1) / 2, n, m);         // even subsequence
        oddEvenMerge(arr, lo + r, m2 / 2, n, m);           // odd subsequence
      }

      if (m2 % 2 != 0) {
        for (int i = lo; i + r < lo + n; i += m) {
          oddEvenMergeCompare(arr, i, i + r);
        }
      } else {
        for (int i = lo + r; i + r < lo + n; i += m) {
          oddEvenMergeCompare(arr, i, i + r);
        }
      }
    } else {
      if (n > r) {
        oddEvenMergeCompare(arr, lo, lo + r);
      }
    }
  }

  private static void oddEvenMergeSort(int[] arr, int lo, int n) {
    if (n > 1) {
      int m = n / 2;
      oddEvenMergeSort(arr, lo, m);
      oddEvenMergeSort(arr, lo + m, n - m);
      oddEvenMerge(arr, lo, m, n, 1);
    }
  }

  public static void sort(int[] arr) {
    oddEvenMergeSort(arr, 0, arr.length);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
