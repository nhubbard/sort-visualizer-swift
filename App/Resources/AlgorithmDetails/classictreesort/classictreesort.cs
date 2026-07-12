using System;

public class ClassicTreeSort {
  private static int idx;

  private static void Traverse(int[] arr, int[] temp, int[] lower, int[] upper, int r) {
    if (lower[r] != 0) {
      Traverse(arr, temp, lower, upper, lower[r]);
    }
    temp[idx++] = arr[r];
    if (upper[r] != 0) {
      Traverse(arr, temp, lower, upper, upper[r]);
    }
  }

  public static void Sort(int[] arr) {
    int n = arr.Length;
    if (n <= 1) {
      return;
    }
    int[] lower = new int[n];
    int[] upper = new int[n];

    for (int i = 1; i < n; i++) {
      int c = 0;
      while (true) {
        int[] next = arr[i] < arr[c] ? lower : upper;
        if (next[c] == 0) {
          next[c] = i;
          break;
        } else {
          c = next[c];
        }
      }
    }

    int[] temp = new int[n];
    idx = 0;
    Traverse(arr, temp, lower, upper, 0);
    Array.Copy(temp, arr, n);
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
