using System;
using System.Collections.Generic;

public class StableQuickSort
{
  public static int StablePartition(int[] arr, int start, int end)
  {
    int pivotValue = arr[start];
    List<int> leftList = new List<int>();
    List<int> rightList = new List<int>();

    for (int i = start + 1; i <= end; i++)
    {
      if (arr[i] < pivotValue)
      {
        leftList.Add(arr[i]);
      }
      else
      {
        rightList.Add(arr[i]);
      }
    }

    int writeIndex = start;
    foreach (int v in leftList)
    {
      arr[writeIndex++] = v;
    }
    int pivotIndex = writeIndex;
    arr[writeIndex++] = pivotValue;
    foreach (int v in rightList)
    {
      arr[writeIndex++] = v;
    }
    return pivotIndex;
  }

  public static void StableQuickSortRange(int[] arr, int start, int end)
  {
    if (start < end)
    {
      int p = StablePartition(arr, start, end);
      StableQuickSortRange(arr, start, p - 1);
      StableQuickSortRange(arr, p + 1, end);
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    StableQuickSortRange(arr, 0, n - 1);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
