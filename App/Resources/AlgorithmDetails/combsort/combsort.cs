using System;

public class CombSort {
  public static void Sort(int[] arr) {
    int n = arr.Length;
    int sm;
    double shrink = 1.3;
    int gap = n;
    bool sorted = false;
    while (!sorted) {
      gap = (int)Math.Floor(gap / shrink);
      if (gap <= 1) {
        sorted = true;
        gap = 1;
      }
      for (int i = 0; i < n - gap; i++) {
        sm = gap + i;
        if (arr[i] > arr[sm]) {
          (arr[i], arr[sm]) = (arr[sm], arr[i]);
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
