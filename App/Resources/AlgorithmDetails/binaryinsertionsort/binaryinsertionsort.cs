using System;

public class BinaryInsertionSort
{
  public static int BinarySearch(int[] array, int item, int start, int end)
  {
    var low = start;
    var high = end;
    while (low < high)
    {
      var mid = low + (high - low) / 2;
      if (item < array[mid])
      {
        high = mid;
      }
      else
      {
        low = mid + 1;
      }
    }
    return low;
  }

  public static int[] Sort(int[] array)
  {
    for (var i = 1; i < array.Length; i++)
    {
      var item = array[i];
      var pos = BinarySearch(array, item, 0, i);
      var j = i;
      while (j > pos)
      {
        array[j] = array[j - 1];
        j--;
      }
      array[pos] = item;
    }
    return array;
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
