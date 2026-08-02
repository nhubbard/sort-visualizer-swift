using System;

public class MedianQuickBogoSort
{
  public static Random r = new Random();

  public static bool IsSplit(int[] arr, int start, int mid, int end)
  {
    int lowMax = arr[start];
    for (int i = start + 1; i < mid; i++)
    {
      if (arr[i] > lowMax)
      {
        lowMax = arr[i];
      }
    }
    for (int i = mid; i < end; i++)
    {
      if (lowMax > arr[i])
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
    int mid = (start + end) / 2;

    while (!IsSplit(arr, start, mid, end))
    {
      for (int i = end - 1; i > start; i--)
      {
        int j = start + r.Next(i - start + 1);
        (arr[i], arr[j]) = (arr[j], arr[i]);
      }
    }

    Sort(arr, start, mid);
    Sort(arr, mid, end);
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