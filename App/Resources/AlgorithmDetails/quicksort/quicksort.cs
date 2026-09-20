using System;

public class QuickSort
{
  public static int[] Sort(int[] array, int left, int right)
  {
    if (left >= right) return array;
    var i = left;
    var j = right;
    while (i < j)
    {
      while (i < j && array[i] <= array[left]) i++;
      while (array[j] > array[left]) j--;
      if (i < j)
      {
        (array[i], array[j]) = (array[j], array[i]);
      }
    }
    (array[left], array[j]) = (array[j], array[left]);
    Sort(array, left, j - 1);
    Sort(array, j + 1, right);
    return array;
  }

  public static void Main(String[] args)
  {
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56
    };
    Sort(array, 0, array.Length - 1);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
