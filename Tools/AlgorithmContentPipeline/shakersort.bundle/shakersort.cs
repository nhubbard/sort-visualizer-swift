using System;

public class ShakerSort {
  public static void Sort(int[] arr) {
    int n = arr.Length;
    bool swapped = true;
    int start = 0;
    int end = n - 1;
    while (swapped) {
      swapped = false;
      for (int i = start; i < end; i++) {
        if (arr[i] > arr[i + 1]) {
          (arr[i], arr[i + 1]) = (arr[i + 1], arr[i]);
          swapped = true;
        }
      }
      if (!swapped) {
        break;
      }
      swapped = false;
      end--;
      for (int i = end - 1; i >= start; i--) {
        if (arr[i] > arr[i + 1]) {
          (arr[i], arr[i + 1]) = (arr[i + 1], arr[i]);
          swapped = true;
        }
      }
      start++;
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