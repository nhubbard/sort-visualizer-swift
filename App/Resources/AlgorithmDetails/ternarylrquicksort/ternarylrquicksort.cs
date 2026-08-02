using System;

public class TernaryLRQuickSort
{
  private static int Compare3(int[] arr, int a, int b)
  {
    if (arr[a] == arr[b])
      return 0;
    return arr[a] > arr[b] ? 1 : -1;
  }

  private static int SelectPivot(int[] arr, int lo, int hi)
  {
    int mid = (lo + hi) / 2;
    int cLoMid = Compare3(arr, lo, mid);
    if (cLoMid == 0)
      return lo;
    int cLoHi = Compare3(arr, lo, hi - 1);
    int cMidHi = Compare3(arr, mid, hi - 1);
    if (cLoHi == 0 || cMidHi == 0)
      return hi - 1;

    if (cLoMid < 0)
    {
      return cMidHi < 0 ? mid : (cLoHi < 0 ? hi - 1 : lo);
    }
    else
    {
      return cMidHi > 0 ? mid : (cLoHi < 0 ? lo : hi - 1);
    }
  }

  private static void QuicksortTernaryLR(int[] arr, int lo, int hi)
  {
    if (hi <= lo)
      return;

    int piv = SelectPivot(arr, lo, hi + 1);
    (arr[piv], arr[hi]) = (arr[hi], arr[piv]);
    int pivotIndex = hi;

    int i = lo,
      j = hi - 1;
    int p = lo,
      q = hi - 1;

    while (true)
    {
      int cmp;
      while (i <= j && (cmp = Compare3(arr, i, pivotIndex)) <= 0)
      {
        if (cmp == 0)
        {
          (arr[i], arr[p]) = (arr[p], arr[i]);
          p++;
        }
        i++;
      }
      while (i <= j && (cmp = Compare3(arr, j, pivotIndex)) >= 0)
      {
        if (cmp == 0)
        {
          (arr[j], arr[q]) = (arr[q], arr[j]);
          q--;
        }
        j--;
      }
      if (i > j)
        break;
      (arr[i], arr[j]) = (arr[j], arr[i]);
      i++;
      j--;
    }

    (arr[i], arr[hi]) = (arr[hi], arr[i]);

    int numLess = i - p;
    int numGreater = q - j;

    j = i - 1;
    i = i + 1;

    int pe = lo + Math.Min(p - lo, numLess);
    for (int k = lo; k < pe; k++, j--)
    {
      (arr[k], arr[j]) = (arr[j], arr[k]);
    }

    int qe = hi - 1 - Math.Min(hi - 1 - q, numGreater - 1);
    for (int k = hi - 1; k > qe; k--, i++)
    {
      (arr[i], arr[k]) = (arr[k], arr[i]);
    }

    QuicksortTernaryLR(arr, lo, lo + numLess - 1);
    QuicksortTernaryLR(arr, hi - numGreater + 1, hi);
  }

  public static void Sort(int[] arr)
  {
    QuicksortTernaryLR(arr, 0, arr.Length - 1);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}