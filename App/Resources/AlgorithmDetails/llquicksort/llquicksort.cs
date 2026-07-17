using System;

public class LLQuickSort
{
  private static int Partition(int[] arr, int lo, int hi)
  {
    int pivot = arr[hi];
    int i = lo;
    for (int j = lo; j < hi; j++)
    {
      if (arr[j] < pivot)
      {
        (arr[i], arr[j]) = (arr[j], arr[i]);
        i++;
      }
    }
    (arr[i], arr[hi]) = (arr[hi], arr[i]);
    return i;
  }

  private static void QuickSort(int[] arr, int lo, int hi)
  {
    if (lo < hi)
    {
      int p = Partition(arr, lo, hi);
      QuickSort(arr, lo, p - 1);
      QuickSort(arr, p + 1, hi);
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
