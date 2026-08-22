using System;

public class PairwiseMergeSortRecursive
{
  private static int end;

  private static void CompSwap(int[] array, int a, int b)
  {
    if (b < end && array[a] > array[b])
    {
      (array[a], array[b]) = (array[b], array[a]);
    }
  }

  private static void PairwiseMerge(int[] array, int a, int b)
  {
    var m = (a + b) / 2;
    var m1 = (a + m) / 2;
    var g = m - m1;

    for (var i = 0; i < m - m1; i++)
    {
      var j = m1;
      var k = g;
      while (k > 0)
      {
        CompSwap(array, j + i, j + i + k);
        k >>= 1;
        j -= (k - (i & k));
      }
    }
    if (b - a > 4)
    {
      PairwiseMerge(array, m, b);
    }
  }

  private static void PairwiseMergeSort(int[] array, int a, int b)
  {
    var m = (a + b) / 2;
    var i = a;
    var j = m;
    while (i < m)
    {
      CompSwap(array, i, j);
      i++;
      j++;
    }
    if (b - a > 2)
    {
      PairwiseMergeSort(array, a, m);
      PairwiseMergeSort(array, m, b);
      PairwiseMerge(array, a, b);
    }
  }

  public static int[] Sort(int[] array)
  {
    var length = array.Length;
    end = length;

    var n = 1;
    while (n < length)
      n <<= 1;

    PairwiseMergeSort(array, 0, n);
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