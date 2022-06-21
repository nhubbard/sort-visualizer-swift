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
    // Specific to bitonic sort: size must be power of 2.
    int[] array = {35, 74, 71, 72, 30, 53, 9, 0};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
