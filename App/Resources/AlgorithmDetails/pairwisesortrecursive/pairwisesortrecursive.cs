using System;

public class PairwiseSortRecursive
{
  private static void CompSwap(int[] arr, int a, int b)
  {
    if (arr[a] > arr[b])
    {
      (arr[a], arr[b]) = (arr[b], arr[a]);
    }
  }

  private static void PairwiseRecursive(int[] arr, int start, int end, int gap)
  {
    if (start == end - gap)
      return;
    var b = start + gap;
    while (b < end)
    {
      CompSwap(arr, b - gap, b);
      b += 2 * gap;
    }

    if (((end - start) / gap) % 2 == 0)
    {
      PairwiseRecursive(arr, start, end, gap * 2);
      PairwiseRecursive(arr, start + gap, end + gap, gap * 2);
    }
    else
    {
      PairwiseRecursive(arr, start, end + gap, gap * 2);
      PairwiseRecursive(arr, start + gap, end, gap * 2);
    }

    var a = 1;
    while (a < (end - start) / gap)
    {
      a = (a * 2) + 1;
    }

    b = start + gap;
    while (b + gap < end)
    {
      var c = a;
      while (c > 1)
      {
        c /= 2;
        if (b + (c * gap) < end)
        {
          CompSwap(arr, b, b + (c * gap));
        }
      }
      b += 2 * gap;
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    PairwiseRecursive(arr, 0, n, 1);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}