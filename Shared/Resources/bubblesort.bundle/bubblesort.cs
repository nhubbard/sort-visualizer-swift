using System;

public class BubbleSort {
  public static void Sort(int[] arr, int n) {
    for (int c = 0; c < n - 1; c++) {
      for (int d = 0; d < n - c - 1; d++) {
        if (arr[d] > arr[d + 1]) {
          (arr[d], arr[d + 1]) = (arr[d + 1], arr[d]);
        }
      }
    }
  }

  public static void Main(String[] args) {
    int[] array = {35, 95, 74, 71, 72, 30, 96, 53, 9, 0};
    Sort(array, array.Length);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}