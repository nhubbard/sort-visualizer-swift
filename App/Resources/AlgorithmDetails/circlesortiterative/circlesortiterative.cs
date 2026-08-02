using System;

public class CircleSortIterative
{
  public static int CircleSortRoutine(int[] array, int length, int end)
  {
    var swapCount = 0;
    for (var gap = length / 2; gap > 0; gap /= 2)
    {
      for (var start = 0; start + gap < end; start += 2 * gap)
      {
        var low = start;
        var high = start + 2 * gap - 1;
        while (low < high)
        {
          if (high < end && array[low] > array[high])
          {
            (array[low], array[high]) = (array[high], array[low]);
            swapCount++;
          }
          low++;
          high--;
        }
      }
    }
    return swapCount;
  }

  public static int[] Sort(int[] array)
  {
    var end = array.Length;
    if (end <= 1)
      return array;
    var n = 1;
    while (n < end)
    {
      n <<= 1;
    }

    var numberOfSwaps = 1;
    while (numberOfSwaps != 0)
    {
      numberOfSwaps = CircleSortRoutine(array, n, end);
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