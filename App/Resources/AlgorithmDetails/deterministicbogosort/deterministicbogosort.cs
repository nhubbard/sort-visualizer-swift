using System;

public class DeterministicBogoSort {
  public static bool IsSorted(int[] arr) {
    for (int i = 0; i < arr.Length - 1; i++) {
      if (arr[i] > arr[i + 1]) {
        return false;
      }
    }
    return true;
  }

  public static bool PermutationSort(int[] arr, int depth, int n) {
    if (depth >= n - 1) {
      return IsSorted(arr);
    }
    for (int i = n - 1; i > depth; i--) {
      if (PermutationSort(arr, depth + 1, n)) {
        return true;
      }
      if ((n - depth) % 2 == 0) {
        (arr[depth], arr[i]) = (arr[i], arr[depth]);
      } else {
        (arr[depth], arr[n - 1]) = (arr[n - 1], arr[depth]);
      }
    }
    return PermutationSort(arr, depth + 1, n);
  }

  public static void Sort(int[] arr) {
    int n = arr.Length;
    PermutationSort(arr, 0, n);
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 14, 23};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
