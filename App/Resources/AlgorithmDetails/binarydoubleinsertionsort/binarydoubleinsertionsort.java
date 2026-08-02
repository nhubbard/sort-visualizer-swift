import java.util.Arrays;

public final class binarydoubleinsertionsort {
  private static int leftBinarySearch(int[] array, int a, int b, int val) {
    int lo = a;
    int hi = b;
    while (lo < hi) {
      int mid = lo + (hi - lo) / 2;
      if (val <= array[mid]) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    return lo;
  }

  private static int rightBinarySearch(int[] array, int a, int b, int val) {
    int lo = a;
    int hi = b;
    while (lo < hi) {
      int mid = lo + (hi - lo) / 2;
      if (val < array[mid]) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    return lo;
  }

  private static void insertToLeft(int[] array, int a, int b, int temp) {
    while (a > b) {
      array[a] = array[a - 1];
      a--;
    }
    array[b] = temp;
  }

  private static void insertToRight(int[] array, int a, int b, int temp) {
    while (a < b) {
      array[a] = array[a + 1];
      a++;
    }
    array[a] = temp;
  }

  private static void doubleInsertion(int[] array, int a, int b) {
    if (b - a < 2) {
      return;
    }

    int j = a + (b - a - 2) / 2 + 1;
    int i = a + (b - a - 1) / 2;

    if (j > i && array[i] > array[j]) {
      int tmp = array[i];
      array[i] = array[j];
      array[j] = tmp;
    }
    i--;
    j++;

    while (j < b) {
      if (array[i] > array[j]) {
        int l = array[j];
        int r = array[i];
        int m = rightBinarySearch(array, i + 1, j, l);
        insertToRight(array, i, m - 1, l);
        int dest = leftBinarySearch(array, m, j, r);
        insertToLeft(array, j, dest, r);
      } else {
        int l = array[i];
        int r = array[j];
        int m = leftBinarySearch(array, i + 1, j, l);
        insertToRight(array, i, m - 1, l);
        int dest = rightBinarySearch(array, m, j, r);
        insertToLeft(array, j, dest, r);
      }
      i--;
      j++;
    }
  }

  public static void sort(int[] arr) {
    if (arr.length > 1) {
      doubleInsertion(arr, 0, arr.length);
    }
  }

  public static void main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
