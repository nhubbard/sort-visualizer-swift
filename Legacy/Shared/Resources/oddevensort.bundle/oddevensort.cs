using System;

public class OddEvenSort {
  public static void Sort(int[] arr) {
    var n = arr.Length;
    var sorted = false;
    while (!sorted) {
      sorted = true;
      for (int i = 1; i < n - 1; i += 2) {
        if (arr[i] > arr[i + 1]) {
          (arr[i], arr[i + 1]) = (arr[i + 1], arr[i]);
          sorted = false;
        }
      }
      for (int i = 0; i < n - 1; i += 2) {
        if (arr[i] > arr[i + 1]) {
          (arr[i], arr[i + 1]) = (arr[i + 1], arr[i]);
          sorted = false;
        }
      }
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