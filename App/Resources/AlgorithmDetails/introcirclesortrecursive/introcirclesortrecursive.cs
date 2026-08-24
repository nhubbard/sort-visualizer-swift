using System;

public class IntroCircleSortRecursive
{
  public static int CircleSortRoutine(int[] array, int lo, int hi, int end)
  {
    if (lo == hi)
      return 0;
    var low = lo;
    var high = hi;
    var mid = (hi - lo) / 2;
    var swapCount = 0;
    while (lo < hi)
    {
      if (hi < end && array[lo] > array[hi])
      {
        (array[lo], array[hi]) = (array[hi], array[lo]);
        swapCount++;
      }
      lo++;
      hi--;
    }
    swapCount += CircleSortRoutine(array, low, low + mid, end);
    if (low + mid + 1 < end)
    {
      swapCount += CircleSortRoutine(array, low + mid + 1, high, end);
    }
    return swapCount;
  }

  public static void BinaryInsertionSort(int[] array, int end)
  {
    for (var i = 1; i < end; i++)
    {
      var value = array[i];
      var lo = 0;
      var hi = i;
      while (lo < hi)
      {
        var mid = lo + (hi - lo) / 2;
        if (value < array[mid])
        {
          hi = mid;
        }
        else
        {
          lo = mid + 1;
        }
      }
      var j = i;
      while (j > lo)
      {
        array[j] = array[j - 1];
        j--;
      }
      array[lo] = value;
    }
  }

  public static int[] Sort(int[] array)
  {
    var end = array.Length;
    if (end <= 1)
      return array;
    var n = 1;
    var threshold = 0;
    while (n < end)
    {
      n <<= 1;
      threshold++;
    }
    threshold /= 2;

    var iterations = 0;
    while (true)
    {
      iterations++;
      if (iterations >= threshold)
      {
        BinaryInsertionSort(array, end);
        return array;
      }
      if (CircleSortRoutine(array, 0, n - 1, end) == 0)
      {
        return array;
      }
    }
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}