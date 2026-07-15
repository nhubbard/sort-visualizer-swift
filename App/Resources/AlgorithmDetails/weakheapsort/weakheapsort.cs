using System;

public class WeakHeapSort {
  public static void Merge(int[] arr, bool[] flags, int i, int j) {
    if (arr[i] < arr[j]) {
      flags[j] = !flags[j];
      (arr[i], arr[j]) = (arr[j], arr[i]);
    }
  }

  public static void Sort(int[] arr) {
    int n = arr.Length;
    bool[] flags = new bool[n];

    for (int i = n - 1; i > 0; i--) {
      int j = i;
      while ((j & 1) == (flags[j >> 1] ? 1 : 0)) {
        j >>= 1;
      }
      int gparent = j >> 1;
      Merge(arr, flags, gparent, i);
    }

    for (int i = n - 1; i > 1; i--) {
      (arr[0], arr[i]) = (arr[i], arr[0]);
      int x = 1;
      while (true) {
        int y = 2 * x + (flags[x] ? 1 : 0);
        if (y >= i) {
          break;
        }
        x = y;
      }
      while (x > 0) {
        Merge(arr, flags, 0, x);
        x >>= 1;
      }
    }
    (arr[0], arr[1]) = (arr[1], arr[0]);
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
