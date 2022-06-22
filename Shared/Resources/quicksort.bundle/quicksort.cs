using System;

public class QuickSort {
  public static int[] Sort(int[] array, int left, int right) {
    var i = left;
    var j = right;
    var pivot = array[left];
    while (i <= j) {
      while (array[i] < pivot) {
        i++;
      }
      while (array[j] > pivot) {
        j--;
      }
      if (i <= j) {
        (array[i], array[j]) = (array[j], array[i]);
        i++;
        j--;
      }
    }
    if (left < j)
      Sort(array, left, j);
    if (i < right)
      Sort(array, i, right);
    return array;
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    Sort(array, 0, array.Length - 1);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}