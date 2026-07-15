using System;

public class BubbleBogoSort {
  public static Random r = new Random();

  public static bool IsSorted(int[] arr) {
    for (int i = 1; i < arr.Length; i++) {
      if (arr[i - 1] > arr[i]) {
        return false;
      }
    }
    return true;
  }

  public static void Sort(int[] arr) {
    int n = arr.Length;
    while (!IsSorted(arr)) {
      int index = r.Next(0, n - 1);
      if (arr[index] > arr[index + 1]) {
        (arr[index], arr[index + 1]) = (arr[index + 1], arr[index]);
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
