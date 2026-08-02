using System;

public class BoseNelsonSortRecursive
{
  private static void CompSwap(int[] arr, int start, int end)
  {
    if (arr[start] > arr[end])
    {
      (arr[start], arr[end]) = (arr[end], arr[start]);
    }
  }

  private static void Merge(int[] arr, int start1, int len1, int start2, int len2)
  {
    if (len1 == 1 && len2 == 1)
    {
      CompSwap(arr, start1, start2);
    }
    else if (len1 == 1 && len2 == 2)
    {
      CompSwap(arr, start1, start2 + 1);
      CompSwap(arr, start1, start2);
    }
    else if (len1 == 2 && len2 == 1)
    {
      CompSwap(arr, start1, start2);
      CompSwap(arr, start1 + 1, start2);
    }
    else
    {
      var mid1 = len1 / 2;
      var mid2 = len1 % 2 == 1 ? len2 / 2 : (len2 + 1) / 2;
      Merge(arr, start1, mid1, start2, mid2);
      Merge(arr, start1 + mid1, len1 - mid1, start2 + mid2, len2 - mid2);
      Merge(arr, start1 + mid1, len1 - mid1, start2, mid2);
    }
  }

  private static void BoseNelson(int[] arr, int start, int length)
  {
    if (length > 1)
    {
      var mid = length / 2;
      BoseNelson(arr, start, mid);
      BoseNelson(arr, start + mid, length - mid);
      Merge(arr, start, mid, start + mid, length - mid);
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    BoseNelson(arr, 0, n);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}