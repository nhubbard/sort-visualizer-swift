using System;

public class SnuffleSort
{
  private static void SnuffleSortHelper(int[] arr, int start, int stop)
  {
    if (stop - start + 1 >= 2)
    {
      if (arr[start].CompareTo(arr[stop]) > 0)
      {
        (arr[start], arr[stop]) = (arr[stop], arr[start]);
      }
      if (stop - start + 1 >= 3)
      {
        int mid = (stop - start) / 2 + start;
        int iterations = (stop - start + 1) / 2;
        for (int i = 0; i < iterations; i++)
        {
          SnuffleSortHelper(arr, start, mid);
          SnuffleSortHelper(arr, mid, stop);
        }
      }
    }
  }

  public static void Sort(int[] arr)
  {
    SnuffleSortHelper(arr, 0, arr.Length - 1);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}