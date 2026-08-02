using System;

public class WeaveMergeSort
{
  private static void MultiSwap(int[] arr, int pos, int to)
  {
    if (to - pos > 0)
    {
      for (int i = pos; i < to; i++)
      {
        (arr[i], arr[i + 1]) = (arr[i + 1], arr[i]);
      }
    }
    else
    {
      for (int i = pos; i > to; i--)
      {
        (arr[i], arr[i - 1]) = (arr[i - 1], arr[i]);
      }
    }
  }

  private static void WeaveInsert(int[] arr, int start, int end)
  {
    for (int j = start; j < end; j++)
    {
      int pos = j;
      while (pos > start && arr[pos] <= arr[pos - 1])
      {
        (arr[pos], arr[pos - 1]) = (arr[pos - 1], arr[pos]);
        pos--;
      }
    }
  }

  private static void WeaveMerge(int[] arr, int min, int max, int mid)
  {
    int target = mid - min;
    for (int i = 1; i <= target; i++)
    {
      MultiSwap(arr, mid + i, min + (i * 2) - 1);
    }
    WeaveInsert(arr, min, max + 1);
  }

  private static void WeaveMergeSortRange(int[] arr, int min, int max)
  {
    if (max - min == 0)
    {
      return;
    }
    else if (max - min == 1)
    {
      if (arr[min] > arr[max])
      {
        (arr[min], arr[max]) = (arr[max], arr[min]);
      }
    }
    else
    {
      int mid = (min + max) / 2;
      WeaveMergeSortRange(arr, min, mid);
      WeaveMergeSortRange(arr, mid + 1, max);
      WeaveMerge(arr, min, max, mid);
    }
  }

  public static void Sort(int[] arr)
  {
    if (arr.Length > 1)
    {
      WeaveMergeSortRange(arr, 0, arr.Length - 1);
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