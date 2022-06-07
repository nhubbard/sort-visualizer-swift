using System;

public class SelectionSort {
  public static void Sort(int[] arr) {
    int n = arr.Length;
    for (int i = 0; i < n - 1; i++) {
      int minIdx = i;
      for (int j = i + 1; j < n; j++) {
        if (arr[j] < arr[minIdx]) {
          minIdx = j;
        }
      }
      (arr[minIdx], arr[i]) = (arr[i], arr[minIdx]);
    }
  }

  public static void Main(String[] args) {
    int[] array = {35, 95, 74, 71, 72, 30, 96, 53, 9, 0};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}