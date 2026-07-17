using System;

public class TernaryLLQuickSort
{
  public static int Compare3(int[] arr, int a, int b)
  {
    if (arr[a] == arr[b])
      return 0;
    return arr[a] > arr[b] ? 1 : -1;
  }

  public static int SelectPivot(int[] arr, int lo, int hi)
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

  public static (int First, int Second) PartitionTernaryLL(int[] arr, int lo, int hi)
  {
    int p = SelectPivot(arr, lo, hi);
    (arr[p], arr[hi - 1]) = (arr[hi - 1], arr[p]);
    int pivotIndex = hi - 1;

    int i = lo;
    int k = hi - 1;

    for (int j = lo; j < k; j++)
    {
      int cmp = Compare3(arr, j, pivotIndex);
      if (cmp == 0)
      {
        k--;
        (arr[k], arr[j]) = (arr[j], arr[k]);
        j--;
      }
      else if (cmp < 0)
      {
        (arr[i], arr[j]) = (arr[j], arr[i]);
        i++;
      }
    }

    for (int s = 0; s < hi - k; s++)
    {
      (arr[i + s], arr[hi - 1 - s]) = (arr[hi - 1 - s], arr[i + s]);
    }

    return (i, i + (hi - k));
  }

  public static void QuicksortTernaryLL(int[] arr, int lo, int hi)
  {
    if (lo + 1 < hi)
    {
      var mid = PartitionTernaryLL(arr, lo, hi);
      QuicksortTernaryLL(arr, lo, mid.First);
      QuicksortTernaryLL(arr, mid.Second, hi);
    }
  }

  public static void Sort(int[] arr)
  {
    QuicksortTernaryLL(arr, 0, arr.Length);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
