using System;
using System.Collections.Generic;

public class BinaryMergeSort
{
  private const int Threshold = 32;

  public static void InsertionSort(int[] arr, int start, int end)
  {
    for (int i = start + 1; i < end; i++)
    {
      int j = i;
      while (j > start && arr[j] < arr[j - 1])
      {
        (arr[j - 1], arr[j]) = (arr[j], arr[j - 1]);
        j--;
      }
    }
  }

  public static void Merge(int[] arr, int start, int mid, int end)
  {
    int low = start;
    int high = mid;
    var merged = new List<int>(end - start);
    while (low < mid && high < end)
    {
      if (arr[high] < arr[low])
      {
        merged.Add(arr[high++]);
      }
      else
      {
        merged.Add(arr[low++]);
      }
    }
    while (low < mid)
    {
      merged.Add(arr[low++]);
    }
    while (high < end)
    {
      merged.Add(arr[high++]);
    }
    for (int i = 0; i < merged.Count; i++)
    {
      arr[start + i] = merged[i];
    }
  }

  public static void MergeSort(int[] arr, int start, int end)
  {
    if (end - start <= Threshold)
    {
      InsertionSort(arr, start, end);
      return;
    }
    int mid = start + (end - start) / 2;
    MergeSort(arr, start, mid);
    MergeSort(arr, mid, end);
    Merge(arr, start, mid, end);
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n < 2)
      return;
    MergeSort(arr, 0, n);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
