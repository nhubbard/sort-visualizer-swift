using System;

public class DiamondSortIterative
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
    int p = 1;
    while (p < n)
    {
      p *= 2;
    }

    int m = 4;
    while (m <= p)
    {
      for (int k = 0; k < m / 2; k++)
      {
        int cnt = k <= m / 4 ? k : m / 2 - k;
        int j = 0;
        while (j < n)
        {
          if (j + cnt + 1 < n)
          {
            int i = j + cnt;
            while (i + 1 < Math.Min(n, j + m - cnt))
            {
              CompSwap(arr, i, i + 1);
              i += 2;
            }
          }
          j += m;
        }
      }
      m *= 2;
    }
    m /= 2;
    for (int k = 0; k <= m / 2; k++)
    {
      int i = k;
      while (i + 1 < Math.Min(n, m - k))
      {
        CompSwap(arr, i, i + 1);
        i += 2;
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