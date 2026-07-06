using System;

public class PancakeSort {
  public static void Flip(int[] arr, int n) {
    var left = 0;
    while (left < n) {
      (arr[left], arr[n]) = (arr[n], arr[left]);
      n--;
      left++;
    }
  }
  
  public static int MaxIndex(int[] arr, int n) {
    var index = 0;
    for (var i = 0; i < n; i++) {
      if (arr[i] > arr[index]) {
        index = i;
      }
    }
    return index;
  }

  public static void Sort(int[] arr) {
    var n = arr.Length;
    while (n > 1) {
      var max = MaxIndex(arr, n);
      if (max != n) {
        Flip(arr, max);
        Flip(arr, n - 1);
      }
      n--;
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