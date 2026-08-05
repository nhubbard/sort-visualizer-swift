using System;

public class RotateLsdRadixSort
{
  private const int RadixBase = 10;

  // Extracts the digit at `place` (0 = ones place) from `value`, in RadixBase.
  private static int DigitAt(int value, int place)
  {
    int divisor = 1;
    for (int i = 0; i < place; i++)
    {
      divisor *= RadixBase;
    }
    return (value / divisor) % RadixBase;
  }

  // Swaps the two equal-length adjacent blocks [a, a+len) and [b, b+len).
  private static void MultiSwap(int[] arr, int a, int b, int len)
  {
    for (int i = 0; i < len; i++)
    {
      (arr[a + i], arr[b + i]) = (arr[b + i], arr[a + i]);
    }
  }

  // Rotates the adjacent blocks [a, m) and [m, b) into swapped order in place,
  // using only block-swaps -- no auxiliary buffer.
  private static void RotateBlock(int[] arr, int a, int m, int b)
  {
    int l = m - a;
    int r = b - m;
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

  // Finds the leftmost index in [a, b) whose digit-`place` value is >= d,
  // assuming [a, b) is already sorted by that digit.
  private static int DigitLowerBound(int[] arr, int a, int b, int d, int place)
  {
    while (a < b)
    {
      int mid = (a + b) / 2;
      if (DigitAt(arr[mid], place) >= d)
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

  // Merges the two adjacent digit-sorted runs [a, m) and [m, b), whose digit-`place`
  // values are known to lie in [da, db), by rotating the below-threshold prefixes of
  // both runs together and recursing into the two halves that produces.
  private static void MergeByDigit(int[] arr, int a, int m, int b, int da, int db, int place)
  {
    if (b - a < 2 || db - da < 2)
    {
      return;
    }
    int dm = (da + db) / 2;
    int m1 = DigitLowerBound(arr, a, m, dm, place);
    int m2 = DigitLowerBound(arr, m, b, dm, place);
    RotateBlock(arr, m1, m, m2);
    int newM = m1 + (m2 - m);
    MergeByDigit(arr, newM, m2, b, dm, db, place);
    MergeByDigit(arr, a, m1, newM, da, dm, place);
  }

  // Sorts [a, b) by digit-`place` alone via ordinary merge-sort recursion on the
  // index range, merging with MergeByDigit instead of a linear merge.
  private static void DigitMergeSort(int[] arr, int a, int b, int place)
  {
    if (b - a < 2)
    {
      return;
    }
    int mid = (a + b) / 2;
    DigitMergeSort(arr, a, mid, place);
    DigitMergeSort(arr, mid, b, place);
    MergeByDigit(arr, a, mid, b, 0, RadixBase, place);
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n < 2)
    {
      return;
    }
    int maxValue = arr[0];
    for (int i = 1; i < n; i++)
    {
      if (arr[i] > maxValue)
      {
        maxValue = arr[i];
      }
    }
    int maxPlace = 0;
    int probe = RadixBase;
    while (probe <= maxValue)
    {
      maxPlace++;
      probe *= RadixBase;
    }
    for (int place = 0; place <= maxPlace; place++)
    {
      DigitMergeSort(arr, 0, n, place);
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