using System;

public class SlowSort {
  public static void SlowSortRange(int[] array, int i, int j) {
    if (i >= j) {
      return;
    }
    var m = i + (j - i) / 2;
    SlowSortRange(array, i, m);
    SlowSortRange(array, m + 1, j);
    if (array[m] > array[j]) {
      (array[m], array[j]) = (array[j], array[m]);
    }
    SlowSortRange(array, i, j - 1);
  }

  public static int[] Sort(int[] array) {
    SlowSortRange(array, 0, array.Length - 1);
    return array;
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
