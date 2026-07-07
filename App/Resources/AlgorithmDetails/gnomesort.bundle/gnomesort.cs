using System;

public class GnomeSort {
  public static void Sort(int[] arr) {
    int n = arr.Length;
    int index = 0;
    while (index < n) {
      if (index == 0) {
        index++;
      }
      if (arr[index] >= arr[index - 1]) {
        index++;
      } else {
        (arr[index], arr[index - 1]) = (arr[index - 1], arr[index]);
        index--;
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