using System;

public class BlockSwapMergeSort
{
  private static void MultiSwap(int[] arr, int a, int b, int len)
  {
    for (int i = 0; i < len; i++)
    {
      int t = arr[a + i];
      arr[a + i] = arr[b + i];
      arr[b + i] = t;
    }
  }

  private static int BinarySearchMid(int[] arr, int start, int mid, int end)
  {
    int a = 0;
    int b = Math.Min(mid - start, end - mid);
    int m = a + (b - a) / 2;
    while (b > a)
    {
      if (arr[mid - m - 1] > arr[mid + m])
      {
        a = m + 1;
      }
      else
      {
        b = m;
      }
      m = a + (b - a) / 2;
    }
    return m;
  }

  private static void MultiSwapMerge(int[] arr, int start, int mid, int end)
  {
    int m = BinarySearchMid(arr, start, mid, end);
    while (m > 0)
    {
      MultiSwap(arr, mid - m, mid, m);
      MultiSwapMerge(arr, mid, mid + m, end);
      end = mid;
      mid -= m;
      m = BinarySearchMid(arr, start, mid, end);
    }
  }

  private static void MultiSwapMergeSort(int[] arr, int a, int b)
  {
    int len = b - a;
    int j = 1;
    while (j < len)
    {
      int i;
      for (i = a; i + 2 * j <= b; i += 2 * j)
      {
        MultiSwapMerge(arr, i, i + j, i + 2 * j);
      }
      if (i + j < b)
      {
        MultiSwapMerge(arr, i, i + j, b);
      }
      j *= 2;
    }
  }

  public static int[] Sort(int[] array)
  {
    MultiSwapMergeSort(array, 0, array.Length);
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
