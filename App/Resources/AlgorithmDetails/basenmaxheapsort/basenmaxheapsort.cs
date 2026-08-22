using System;

public class BaseNMaxHeapSort
{
  private const int Base = 4;

  public static void SiftDown(int[] arr, int node, int stop)
  {
    int left = node * Base + 1;
    if (left >= stop)
    {
      return;
    }
    int maxIndex = left;
    for (int i = left + 1; i < left + Base && i < stop; i++)
    {
      if (arr[maxIndex] < arr[i])
      {
        maxIndex = i;
      }
    }
    if (arr[node] < arr[maxIndex])
    {
      (arr[node], arr[maxIndex]) = (arr[maxIndex], arr[node]);
      SiftDown(arr, maxIndex, stop);
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    for (int i = n - 1; i >= 0; i--)
    {
      SiftDown(arr, i, n);
    }
    for (int end = n - 1; end > 0; end--)
    {
      (arr[0], arr[end]) = (arr[end], arr[0]);
      SiftDown(arr, 0, end);
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