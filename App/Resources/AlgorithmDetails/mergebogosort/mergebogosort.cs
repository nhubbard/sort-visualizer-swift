using System;
using System.Collections.Generic;
using System.Linq;

public class MergeBogoSort
{
  public static Random r = new Random();

  public static bool IsSorted(int[] arr, int start, int end)
  {
    for (int i = start; i < end - 1; i++)
    {
      if (arr[i] > arr[i + 1])
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
    Sort(arr, start, mid);
    Sort(arr, mid, end);

    int[] saved = new int[end - start];
    Array.Copy(arr, start, saved, 0, end - start);

    while (!IsSorted(arr, start, end))
    {
      List<int> indices = new List<int>();
      for (int i = 0; i < end - start; i++)
      {
        indices.Add(i);
      }
      for (int i = indices.Count - 1; i > 0; i--)
      {
        int j = r.Next(i + 1);
        int temp = indices[i];
        indices[i] = indices[j];
        indices[j] = temp;
      }
      HashSet<int> highPositions = new HashSet<int>(indices.Take(end - mid));

      int low = 0,
        high = mid - start;
      for (int offset = 0; offset < end - start; offset++)
      {
        if (highPositions.Contains(offset))
        {
          arr[start + offset] = saved[high];
          high++;
        }
        else
        {
          arr[start + offset] = saved[low];
          low++;
        }
      }
    }
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