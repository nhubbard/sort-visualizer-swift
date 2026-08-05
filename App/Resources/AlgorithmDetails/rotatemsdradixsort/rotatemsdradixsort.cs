using System;

public class RotateMSDRadixSort
{
  private static int IntPow(int b, int exponent)
  {
    var result = 1;
    for (var i = 0; i < exponent; i++)
    {
      result *= b;
    }
    return result;
  }

  private static int GetDigit(int value, int place, int radix)
  {
    return (value / IntPow(radix, place)) % radix;
  }

  private static void MultiSwap(int[] arr, int a, int b, int len)
  {
    for (var i = 0; i < len; i++)
    {
      (arr[a + i], arr[b + i]) = (arr[b + i], arr[a + i]);
    }
  }

  private static void Rotate(int[] arr, int a, int m, int b)
  {
    var l = m - a;
    var r = b - m;
    while (l > 0 && r > 0)
    {
      if (r < l)
      {
        MultiSwap(arr, m - r, m, r);
        b -= r;
        m -= r;
        l -= r;
      }
      else
      {
        MultiSwap(arr, a, m, l);
        a += l;
        m += l;
        r -= l;
      }
    }
  }

  private static int BinSearchDigit(int[] arr, int a, int b, int d, int place, int radix)
  {
    while (a < b)
    {
      var mid = (a + b) / 2;
      if (GetDigit(arr[mid], place, radix) >= d)
      {
        b = mid;
      }
      else
      {
        a = mid + 1;
      }
    }
    return a;
  }

  private static void MergeDigit(
    int[] arr, int a, int m, int b, int da, int db, int place, int radix)
  {
    if (b - a < 2 || db - da < 2)
    {
      return;
    }
    var dm = (da + db) / 2;
    var m1 = BinSearchDigit(arr, a, m, dm, place, radix);
    var m2 = BinSearchDigit(arr, m, b, dm, place, radix);
    Rotate(arr, m1, m, m2);
    var newM = m1 + (m2 - m);
    MergeDigit(arr, newM, m2, b, dm, db, place, radix);
    MergeDigit(arr, a, m1, newM, da, dm, place, radix);
  }

  private static void MergeSortDigit(int[] arr, int a, int b, int place, int radix)
  {
    if (b - a < 2)
    {
      return;
    }
    var mid = (a + b) / 2;
    MergeSortDigit(arr, a, mid, place, radix);
    MergeSortDigit(arr, mid, b, place, radix);
    MergeDigit(arr, a, mid, b, 0, radix, place, radix);
  }

  // Digit-sorts [a, b) in place by `place` using rotation instead of counting
  // buckets, then recurses into every resulting digit bucket one place lower --
  // an ordinary MSD radix sort built entirely out of the LSD variant's
  // rotate/binary-search machinery.
  private static void MsdRotateSort(int[] arr, int a, int b, int place, int radix)
  {
    if (b - a < 2 || place < 0)
    {
      return;
    }
    MergeSortDigit(arr, a, b, place, radix);
    var start = a;
    for (var d = 0; d < radix; d++)
    {
      var end = BinSearchDigit(arr, start, b, d + 1, place, radix);
      MsdRotateSort(arr, start, end, place - 1, radix);
      start = end;
    }
  }

  public static int[] Sort(int[] array)
  {
    if (array.Length <= 1)
    {
      return array;
    }
    var radix = 4;
    var maxValue = array[0];
    foreach (var value in array)
    {
      if (value > maxValue)
      {
        maxValue = value;
      }
    }
    var highestPlace = 0;
    var probe = radix;
    while (probe <= maxValue)
    {
      highestPlace++;
      probe *= radix;
    }
    MsdRotateSort(array, 0, array.Length, highestPlace, radix);
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