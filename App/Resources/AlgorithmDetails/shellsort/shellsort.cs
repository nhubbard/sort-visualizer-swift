using System;

public class ShellSort {
  public static void Sort(int[] arr) {
    int n = arr.Length;
    for (var i = n / 2; i > 0; i /= 2) {
      for (var j = i; j < n; j++) {
        for (var k = j - i; k >= 0; k -= i) {
          if (arr[k + i] >= arr[k]) {
            break;
          } else {
            (arr[k], arr[k + i]) = (arr[k + i], arr[k]);
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