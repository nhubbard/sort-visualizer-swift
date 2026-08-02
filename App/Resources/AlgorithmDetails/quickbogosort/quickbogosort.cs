using System;

public class QuickBogoSort
{
  public static Random r = new Random();

  public static bool IsPartitioned(int[] arr, int start, int pivot, int end)
  {
    for (int i = start; i < pivot; i++)
    {
      if (arr[i] > arr[pivot])
      {
        return false;
      }
    }
    for (int i = pivot + 1; i < end; i++)
    {
      if (arr[pivot] > arr[i])
      {
        return false;
      }
    }
    return true;
  }

  public static void Sort(int[] arr, int start, int end)
  {
    if (start >= end - 1)
    {
      return;
    }

    int pivot = start;

    while (!IsPartitioned(arr, start, pivot, end))
    {
      for (int i = start; i < end; i++)
      {
        int j = r.Next(i, end);
        if (pivot == i)
        {
          pivot = j;
        }
        else if (pivot == j)
        {
          pivot = i;
        }
        (arr[i], arr[j]) = (arr[j], arr[i]);
      }
    }

    Sort(arr, start, pivot);
    Sort(arr, pivot + 1, end);
  }

  public static void Sort(int[] arr)
  {
    Sort(arr, 0, arr.Length);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 14, 23 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}