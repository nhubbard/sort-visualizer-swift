using System;

public class OptimizedStoogeSortStudio
{
  public static bool CompSwap(int[] arr, int a, int b)
  {
    if (arr[a] > arr[b])
    {
      (arr[a], arr[b]) = (arr[b], arr[a]);
      return true;
    }
    return false;
  }

  public static bool StoogeSortRange(int[] arr, int a, int m, int b, bool merge)
  {
    if (a >= m) return false;
    if (b - a == 2) return CompSwap(arr, a, m);

    bool lChange = false;
    bool rChange = false;

    int a2 = (a + a + b) / 3;
    int b2 = (a + b + b + 2) / 3;

    if (m < b2)
    {
      lChange = StoogeSortRange(arr, a, m, b2, merge);
      if (merge)
      {
        rChange = StoogeSortRange(arr, Math.Max(a + b2 - m, a2), b2, b, true);
        if (rChange)
        {
          StoogeSortRange(arr, a + b2 - m, a2, 2 * a2 - a, true);
        }
      }
      else
      {
        rChange = StoogeSortRange(arr, a2, b2, b, false);
        if (rChange)
        {
          StoogeSortRange(arr, a, a2, 2 * a2 - a, true);
        }
      }
    }
    else
    {
      rChange = StoogeSortRange(arr, a2, m, b, merge);
      if (rChange)
      {
        StoogeSortRange(arr, a, a2, a2 + b - m, true);
      }
    }

    return lChange || rChange;
  }

  public static void Sort(int[] arr)
  {
    StoogeSortRange(arr, 0, 1, arr.Length, false);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}