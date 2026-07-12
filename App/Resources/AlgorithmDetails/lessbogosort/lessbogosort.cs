using System;

public class LessBogoSort {
  public static Random r = new Random();

  public static bool IsMinimum(int[] arr, int start, int end) {
    for (int k = start + 1; k < end; k++) {
      if (arr[start] > arr[k]) {
        return false;
      }
    }
    return true;
  }

  public static void ShuffleRange(int[] arr, int start, int end) {
    for (int i = start; i < end - 1; i++) {
      int j = r.Next(i, end);
      (arr[i], arr[j]) = (arr[j], arr[i]);
    }
  }

  public static void Sort(int[] arr) {
    int n = arr.Length;
    for (int i = 0; i < n; i++) {
      while (!IsMinimum(arr, i, n)) {
        ShuffleRange(arr, i, n);
      }
    }
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
