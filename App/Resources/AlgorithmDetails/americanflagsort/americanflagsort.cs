using System;

public class AmericanFlagSort
{
  private static int DigitAt(int value, int divisor, int radix)
  {
    return (value / divisor) % radix;
  }

  private static void FlagSort(int[] array, int low, int high, int divisor, int radix)
  {
    if (high - low <= 1)
    {
      return;
    }

    var count = new int[radix];
    var offset = new int[radix];

    for (var i = low; i < high; i++)
    {
      count[DigitAt(array[i], divisor, radix)]++;
    }

    offset[0] = low;
    for (var d = 1; d < radix; d++)
    {
      offset[d] = offset[d - 1] + count[d - 1];
    }
    var bucketStart = (int[])offset.Clone();

    for (var d = 0; d < radix; d++)
    {
      while (count[d] > 0)
      {
        var origin = offset[d];
        var from = origin;
        var value = array[from];

        do
        {
          var digit = DigitAt(value, divisor, radix);
          var dest = offset[digit]++;
          count[digit]--;
          var displaced = array[dest];
          array[dest] = value;
          value = displaced;
          from = dest;
        } while (from != origin);
      }
    }

    if (divisor > 1)
    {
      for (var d = 0; d < radix; d++)
      {
        var begin = bucketStart[d];
        var end = offset[d];
        if (end - begin > 1)
        {
          FlagSort(array, begin, end, divisor / radix, radix);
        }
      }
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n <= 1)
    {
      return;
    }

    var radix = 10;
    var maxValue = arr[0];
    foreach (var value in arr)
    {
      if (value > maxValue)
      {
        maxValue = value;
      }
    }

    var divisor = 1;
    while (maxValue / divisor >= radix)
    {
      divisor *= radix;
    }

    FlagSort(arr, 0, n, divisor, radix);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}