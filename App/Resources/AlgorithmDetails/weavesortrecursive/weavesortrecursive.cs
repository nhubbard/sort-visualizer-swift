using System;

public class WeaveSortRecursive
{
  private static int end;

  private static void CompSwap(int[] arr, int a, int b)
  {
    if (b < end && arr[a] > arr[b])
    {
      int temp = arr[a];
      arr[a] = arr[b];
      arr[b] = temp;
    }
  }

  private static void Circle(int[] arr, int pos, int ln, int gap)
  {
    if (ln < 2)
    {
      return;
    }
    int i = 0;
    while (2 * i < (ln - 1) * gap)
    {
      CompSwap(arr, pos + i, pos + (ln - 1) * gap - i);
      i += gap;
    }
    Circle(arr, pos, ln / 2, gap);
    if (pos + ln * gap / 2 < end)
    {
      Circle(arr, pos + ln * gap / 2, ln / 2, gap);
    }
  }

  private static void WeaveCircle(int[] arr, int pos, int ln, int gap)
  {
    if (ln < 2)
    {
      return;
    }
    WeaveCircle(arr, pos, ln / 2, 2 * gap);
    WeaveCircle(arr, pos + gap, ln / 2, 2 * gap);
    Circle(arr, pos, ln, gap);
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    end = n;
    int padded = 1;
    while (padded < end)
    {
      padded *= 2;
    }
    WeaveCircle(arr, 0, padded, 1);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}