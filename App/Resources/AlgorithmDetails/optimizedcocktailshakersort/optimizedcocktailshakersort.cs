using System;

public class OptimizedCocktailShakerSort {
  public static int[] Sort(int[] array) {
    int start = 0;
    int end = array.Length - 1;
    while (start < end) {
      int consecSorted = 1;
      for (int i = start; i < end; i++) {
        if (array[i] > array[i + 1]) {
          (array[i], array[i + 1]) = (array[i + 1], array[i]);
          consecSorted = 1;
        } else {
          consecSorted++;
        }
      }
      end -= consecSorted;

      consecSorted = 1;
      for (int j = end; j > start; j--) {
        if (array[j - 1] > array[j]) {
          (array[j - 1], array[j]) = (array[j], array[j - 1]);
          consecSorted = 1;
        } else {
          consecSorted++;
        }
      }
      start += consecSorted;
    }
    return array;
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
