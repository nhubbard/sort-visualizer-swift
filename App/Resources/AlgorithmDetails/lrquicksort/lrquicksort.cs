using System;

public class LRQuickSort
{
  private static void QuickSort(int[] arr, int p, int r)
  {
    if (p >= r)
    {
      return;
    }

    int pivot = arr[p + (r - p + 1) / 2];
    int i = p;
    int j = r;

    while (i <= j)
    {
      while (arr[i] < pivot)
      {
        i++;
      }
      while (arr[j] > pivot)
      {
        j--;
      }
      if (i <= j)
      {
        (arr[i], arr[j]) = (arr[j], arr[i]);
        i++;
        j--;
      }
    }

    if (p < j)
    {
      QuickSort(arr, p, j);
    }
    if (i < r)
    {
      QuickSort(arr, i, r);
    }
  }

  public static void Sort(int[] arr)
  {
    QuickSort(arr, 0, arr.Length - 1);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}