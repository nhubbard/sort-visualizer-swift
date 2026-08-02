using System;

public class PairwiseMergeSortIterative
{
  private static int end;

  private static void CompSwap(int[] array, int a, int b)
  {
    if (b < end && array[a] > array[b])
    {
      (array[a], array[b]) = (array[b], array[a]);
    }
  }

  public static int[] Sort(int[] array)
  {
    var length = array.Length;
    end = length;

    var n = 1;
    while (n < length)
      n <<= 1;

    var k = n >> 1;
    while (k > 0)
    {
      var j = 0;
      while (j < length)
      {
        for (var i = 0; i < k; i++)
        {
          CompSwap(array, j + i, j + k + i);
        }
        j += k << 1;
      }
      k >>= 1;
    }

    k = 2;
    while (k < n)
    {
      var m = k >> 1;
      while (m > 0)
      {
        var j = 0;
        while (j < length)
        {
          var p = m;
          while (p < ((k - m) << 1))
          {
            for (var i = 0; i < m; i++)
            {
              CompSwap(array, j + p + i, j + p + m + i);
            }
            p += m << 1;
          }
          j += k << 1;
        }
        m >>= 1;
      }
      k <<= 1;
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