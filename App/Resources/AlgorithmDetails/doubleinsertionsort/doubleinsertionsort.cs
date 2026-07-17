using System;

public class DoubleInsertionSort
{
  public static void InsertionSort(int[] array, int start, int end)
  {
    var left = start + (end - start) / 2 - 1;
    var right = left + 1;
    if (array[left] > array[right])
    {
      (array[left], array[right]) = (array[right], array[left]);
    }
    left--;
    right++;

    while (left >= start && right < end)
    {
      if (array[left] > array[right])
      {
        var leftItem = array[right];
        var rightItem = array[left];

        var pos = left + 1;
        while (pos <= right && array[pos] <= leftItem)
        {
          array[pos - 1] = array[pos];
          pos++;
        }
        array[pos - 1] = leftItem;

        pos = right - 1;
        while (pos >= left && array[pos] >= rightItem)
        {
          array[pos + 1] = array[pos];
          pos--;
        }
        array[pos + 1] = rightItem;
      }
      else
      {
        var leftItem = array[left];
        var rightItem = array[right];

        var pos = left + 1;
        while (array[pos] < leftItem)
        {
          array[pos - 1] = array[pos];
          pos++;
        }
        array[pos - 1] = leftItem;

        pos = right - 1;
        while (array[pos] > rightItem)
        {
          array[pos + 1] = array[pos];
          pos--;
        }
        array[pos + 1] = rightItem;
      }

      left--;
      right++;
    }

    if (right < end)
    {
      var pos = right - 1;
      var current = array[right];
      while (pos >= start && array[pos] > current)
      {
        array[pos + 1] = array[pos];
        pos--;
      }
      array[pos + 1] = current;
    }
  }

  public static int[] Sort(int[] array)
  {
    if (array.Length > 1)
    {
      InsertionSort(array, 0, array.Length);
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
