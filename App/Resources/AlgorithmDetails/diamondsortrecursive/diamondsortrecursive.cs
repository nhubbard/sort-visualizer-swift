using System;

public class DiamondSortRecursive {
  // [start, stop) is the half-open range being sorted. merge selects whether
  // the two halves are recursively pre-sorted before the fixed diamond
  // comparison pattern below merges them together.
  private static void Sort(int[] arr, int start, int stop, bool merge) {
    if (stop - start == 2) {
      if (arr[start] > arr[stop - 1]) {
        (arr[start], arr[stop - 1]) = (arr[stop - 1], arr[start]);
      }
    } else if (stop - start >= 3) {
      double div = (stop - start) / 4.0;
      int mid = (stop - start) / 2 + start;
      int quarter = (int) div + start;
      int threeQuarters = (int) (div * 3) + start;

      if (merge) {
        Sort(arr, start, mid, true);
        Sort(arr, mid, stop, true);
      }
      Sort(arr, quarter, threeQuarters, false);
      Sort(arr, start, mid, false);
      Sort(arr, mid, stop, false);
      Sort(arr, quarter, threeQuarters, false);
    }
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    Sort(array, 0, array.Length, true);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
