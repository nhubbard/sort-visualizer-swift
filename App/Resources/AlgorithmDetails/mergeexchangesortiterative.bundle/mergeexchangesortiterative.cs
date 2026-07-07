using System;

public class MergeExchangeSort {
  public static void Sort(int[] array) {
    int n = array.Length;
    if (n <= 1) return;
    int t = (int)(Math.Log(n - 1) / Math.Log(2)) + 1;
    int p0 = 1 << (t - 1);
    for (int p = p0; p > 0; p >>= 1) {
      int q = p0;
      int r = 0;
      int d = p;
      while (true) {
        for (int i = 0; i < n - d; i++) {
          if ((i & p) == r && array[i] > array[i + d]) {
            (array[i], array[i + d]) = (array[i + d], array[i]);
          }
        }
        if (q == p) break;
        d = q - p;
        q >>= 1;
        r = p;
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
