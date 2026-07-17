using System;

public class OddEvenMergeSortRecursive
{
  private static void OddEvenMergeCompare(int[] array, int i, int j)
  {
    if (array[i] > array[j])
    {
      (array[i], array[j]) = (array[j], array[i]);
    }
  }

  // lo is the starting position, m2 is the halfway point, n is the length of
  // the piece being merged, and r is the distance of the elements compared.
  private static void OddEvenMerge(int[] array, int lo, int m2, int n, int r)
  {
    int m = r * 2;
    if (m < n)
    {
      if ((n / r) % 2 != 0)
      {
        OddEvenMerge(array, lo, (m2 + 1) / 2, n + r, m); // even subsequence
        OddEvenMerge(array, lo + r, m2 / 2, n - r, m); // odd subsequence
      }
      else
      {
        OddEvenMerge(array, lo, (m2 + 1) / 2, n, m); // even subsequence
        OddEvenMerge(array, lo + r, m2 / 2, n, m); // odd subsequence
      }

      if (m2 % 2 != 0)
      {
        for (int i = lo; i + r < lo + n; i += m)
        {
          OddEvenMergeCompare(array, i, i + r);
        }
      }
      else
      {
        for (int i = lo + r; i + r < lo + n; i += m)
        {
          OddEvenMergeCompare(array, i, i + r);
        }
      }
    }
    else
    {
      if (n > r)
      {
        OddEvenMergeCompare(array, lo, lo + r);
      }
    }
  }

  private static void OddEvenMergeSort(int[] array, int lo, int n)
  {
    if (n > 1)
    {
      int m = n / 2;
      OddEvenMergeSort(array, lo, m);
      OddEvenMergeSort(array, lo + m, n - m);
      OddEvenMerge(array, lo, m, n, 1);
    }
  }

  public static void Sort(int[] array)
  {
    OddEvenMergeSort(array, 0, array.Length);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
