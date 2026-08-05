using System;

public class PancakeInsertionSort
{
  // Reverses arr[0..hi] in place. This "flip" is the only move the algorithm ever performs;
  // there is no per-element shift anywhere.
  private static void Flip(int[] arr, int hi)
  {
    var lo = 0;
    while (lo < hi)
    {
      (arr[lo], arr[hi]) = (arr[hi], arr[lo]);
      lo++;
      hi--;
    }
  }

  // Monobound binary search: locates the index within the ascending run arr[start..end) at
  // which arr[valueIndex] belongs, using one comparison per halving instead of the usual two.
  private static int SearchAscending(int[] arr, int start, int end, int valueIndex)
  {
    var top = end - start;
    while (top > 1)
    {
      var mid = top / 2;
      if (arr[valueIndex] <= arr[end - mid])
      {
        end -= mid;
      }
      top -= mid;
    }
    if (arr[valueIndex] <= arr[end - 1])
    {
      return end - 1;
    }
    return end;
  }

  // Mirror image of SearchAscending for a descending run arr[start..end).
  private static int SearchDescending(int[] arr, int start, int end, int valueIndex)
  {
    var top = end - start;
    while (top > 1)
    {
      var mid = top / 2;
      if (arr[start + mid] > arr[valueIndex])
      {
        start += mid;
      }
      top -= mid;
    }
    if (arr[start] > arr[valueIndex])
    {
      return start + 1;
    }
    return start;
  }

  // Hand-sorts arr[0..n) for n <= 3 via a small decision tree. Returns true if the result runs
  // ascending, false if it runs descending.
  private static bool SortFirstThree(int[] arr, int n)
  {
    if (n < 2)
    {
      return false;
    }
    if (arr[0] > arr[1])
    {
      Flip(arr, 1);
    }
    if (n > 2)
    {
      if (arr[1] > arr[2])
      {
        if (arr[0] > arr[2])
        {
          Flip(arr, 1);
        }
        else
        {
          Flip(arr, 2);
          Flip(arr, 1);
        }
        return false;
      }
      return true;
    }
    return true;
  }

  public static void Sort(int[] arr)
  {
    var n = arr.Length;
    if (n < 2)
    {
      return;
    }

    var ascending = SortFirstThree(arr, n);

    for (var i = 3; i < n; i++)
    {
      if (ascending)
      {
        if (arr[i - 1] <= arr[i])
        {
          // Already fits; the ascending prefix already ends at or below the new element.
          continue;
        }
        if (arr[0] > arr[i])
        {
          // The new element is smaller than everything in the prefix -- one flip turns the
          // whole thing, including the new element, into a descending run.
          Flip(arr, i - 1);
          ascending = false;
          continue;
        }
        var idx = SearchAscending(arr, 0, i, i);
        Flip(arr, i);
        var tail = i - idx;
        Flip(arr, tail);
        Flip(arr, tail - 1);
        ascending = false;
      }
      else
      {
        if (arr[i - 1] > arr[i])
        {
          continue;
        }
        if (arr[0] <= arr[i])
        {
          Flip(arr, i - 1);
          ascending = true;
          continue;
        }
        var idx = SearchDescending(arr, 0, i, i);
        Flip(arr, i);
        var tail = i - idx;
        Flip(arr, tail);
        Flip(arr, tail - 1);
        ascending = true;
      }
    }

    if (!ascending)
    {
      Flip(arr, n - 1);
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