using System;

public class ThreeSmoothCombSortRecursive {
  private static void PowerOfThree(int[] arr, int pos, int gap, int end) {
    if (pos + gap > end) {
      return;
    }

    PowerOfThree(arr, pos, gap * 3, end);
    PowerOfThree(arr, pos + gap, gap * 3, end);
    PowerOfThree(arr, pos + 2 * gap, gap * 3, end);

    for (int i = pos; i + gap < end; i += gap) {
      if (arr[i] > arr[i + gap]) {
        int t = arr[i];
        arr[i] = arr[i + gap];
        arr[i + gap] = t;
      }
    }
  }

  private static void RecursiveComb(int[] arr, int pos, int gap, int end) {
    if (pos + gap > end) {
      return;
    }

    RecursiveComb(arr, pos, gap * 2, end);
    RecursiveComb(arr, pos + gap, gap * 2, end);

    PowerOfThree(arr, pos, gap, end);
  }

  public static void Sort(int[] arr) {
    int n = arr.Length;
    if (n > 1) {
      RecursiveComb(arr, 0, 1, n);
    }
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
