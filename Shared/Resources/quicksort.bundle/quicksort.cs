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
        int temp = array[i];
        array[i] = array[j];
        array[j] = temp;
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
    int[] array = {1, 5, 2, 3, 7, 4, 8, 9};
    Sort(array, 0, array.Length - 1);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}