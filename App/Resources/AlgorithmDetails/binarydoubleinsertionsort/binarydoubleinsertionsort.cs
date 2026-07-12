using System;

public static class BinaryDoubleInsertionSort {
  private static int LeftBinarySearch(int[] array, int a, int b, int val) {
    int lo = a, hi = b;
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

  private static int RightBinarySearch(int[] array, int a, int b, int val) {
    int lo = a, hi = b;
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

  private static void InsertToLeft(int[] array, int a, int b, int temp) {
    while (a > b) {
      array[a] = array[a - 1];
      a--;
    }
    array[b] = temp;
  }

  private static void InsertToRight(int[] array, int a, int b, int temp) {
    while (a < b) {
      array[a] = array[a + 1];
      a++;
    }
    array[a] = temp;
  }

  private static void DoubleInsertion(int[] array, int a, int b) {
    if (b - a < 2) {
      return;
    }

    int j = a + (b - a - 2) / 2 + 1;
    int i = a + (b - a - 1) / 2;

    if (j > i && array[i] > array[j]) {
      (array[i], array[j]) = (array[j], array[i]);
    }
    i--;
    j++;

    while (j < b) {
      if (array[i] > array[j]) {
        int l = array[j];
        int r = array[i];
        int m = RightBinarySearch(array, i + 1, j, l);
        InsertToRight(array, i, m - 1, l);
        int dest = LeftBinarySearch(array, m, j, r);
        InsertToLeft(array, j, dest, r);
      } else {
        int l = array[i];
        int r = array[j];
        int m = LeftBinarySearch(array, i + 1, j, l);
        InsertToRight(array, i, m - 1, l);
        int dest = RightBinarySearch(array, m, j, r);
        InsertToLeft(array, j, dest, r);
      }
      i--;
      j++;
    }
  }

  public static void Sort(int[] arr) {
    if (arr.Length > 1) {
      DoubleInsertion(arr, 0, arr.Length);
    }
  }

  public static void Main() {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    Sort(array);
    Console.WriteLine("[" + string.Join(", ", array) + "]");
  }
}
