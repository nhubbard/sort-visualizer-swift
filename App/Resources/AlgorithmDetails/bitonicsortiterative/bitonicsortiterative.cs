using System;

public class BitonicSort {
  public static void Sort(int[] arr) {
    int n = arr.Length;
    for (int k = 2; k <= n; k *= 2) {
      for (int j = k / 2; j > 0; j /= 2) {
        for (int i = 0; i < n; i++) {
          int l = i ^ j;
          if (l > i) {
            if (((i & k) == 0) && (arr[i] > arr[l]) ||
            (((i & k) != 0) && (arr[i] < arr[l]))) {
              (arr[i], arr[l]) = (arr[l], arr[i]);
            }
          }
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