using System;

public class CreaseSort
{
  private static void CompSwap(int[] arr, int a, int b)
  {
    if (arr[a] > arr[b])
    {
      (arr[a], arr[b]) = (arr[b], arr[a]);
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    int maxVal = 1;
    while (maxVal * 2 < n)
    {
      maxVal *= 2;
    }

    int next = maxVal;
    while (next > 0)
    {
      int i = 0;
      while (i + 1 < n)
      {
        CompSwap(arr, i, i + 1);
        i += 2;
      }

      int j = maxVal;
      while (j >= next && j > 1)
      {
        i = 1;
        while (i + j - 1 < n)
        {
          CompSwap(arr, i, i + j - 1);
          i += 2;
        }
        j /= 2;
      }

      next /= 2;
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