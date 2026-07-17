using System;

public class BitonicSortRecursive
{
  public static int GreatestPowerOfTwoLessThan(int n)
  {
    var k = 1;
    while (k < n)
    {
      k <<= 1;
    }
    return k >> 1;
  }

  public static void Compare(int[] array, int i, int j, bool dir)
  {
    var isGreater = array[i] > array[j];
    if (dir == isGreater)
    {
      (array[i], array[j]) = (array[j], array[i]);
    }
  }

  public static void BitonicMerge(int[] array, int lo, int n, bool dir)
  {
    if (n > 1)
    {
      var m = GreatestPowerOfTwoLessThan(n);
      for (var i = lo; i < lo + n - m; i++)
      {
        Compare(array, i, i + m, dir);
      }
      BitonicMerge(array, lo, m, dir);
      BitonicMerge(array, lo + m, n - m, dir);
    }
  }

  public static void BitonicSort(int[] array, int lo, int n, bool dir)
  {
    if (n > 1)
    {
      var m = n / 2;
      BitonicSort(array, lo, m, !dir);
      BitonicSort(array, lo + m, n - m, dir);
      BitonicMerge(array, lo, n, dir);
    }
  }

  public static int[] Sort(int[] array)
  {
    BitonicSort(array, 0, array.Length, true);
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
