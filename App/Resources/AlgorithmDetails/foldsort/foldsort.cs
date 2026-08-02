using System;

public class FoldSort
{
  private static int end;

  private static void CompSwap(int[] arr, int a, int b)
  {
    if (b < end && arr[a] > arr[b])
    {
      (arr[a], arr[b]) = (arr[b], arr[a]);
    }
  }

  private static void Halver(int[] arr, int low, int high)
  {
    while (low < high)
    {
      CompSwap(arr, low, high);
      low++;
      high--;
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    end = n;
    var ceilLog = 1;
    while ((1 << ceilLog) < n)
      ceilLog++;
    var size2 = 1 << ceilLog;

    var k = size2 >> 1;
    while (k > 0)
    {
      var i = size2;
      while (i >= k)
      {
        var j = 0;
        while (j < end)
        {
          Halver(arr, j, j + i - 1);
          j += i;
        }
        i >>= 1;
      }
      k >>= 1;
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