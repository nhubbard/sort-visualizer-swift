using System;

public class BoseNelsonSortIterative
{
  private static int end;

  private static void CompSwap(int[] array, int a, int b)
  {
    if (b >= end)
      return;
    if (array[a] > array[b])
    {
      (array[a], array[b]) = (array[b], array[a]);
    }
  }

  private static void RangeComp(int[] array, int a, int b, int offset)
  {
    var half = (b - a) / 2;
    var m = a + half;
    var baseIndex = a + offset;
    for (var i = 0; i < half - offset; i++)
    {
      if ((i & ~offset) == i)
      {
        CompSwap(array, baseIndex + i, m + i);
      }
    }
  }

  public static int[] Sort(int[] array)
  {
    end = array.Length;
    if (end <= 1)
      return array;
    var paddedLength = 1;
    while (paddedLength < end)
      paddedLength <<= 1;

    for (var k = 2; k <= paddedLength; k *= 2)
    {
      for (var j = 0; j < k / 2; j++)
      {
        for (var i = 0; i + j < end; i += k)
        {
          RangeComp(array, i, i + k, j);
        }
      }
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
