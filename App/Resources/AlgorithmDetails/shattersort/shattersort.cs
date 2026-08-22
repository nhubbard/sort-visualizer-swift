using System;
using System.Collections.Generic;

public class ShatterSort
{
  public static void InsertionSort(int[] arr, int start, int end)
  {
    for (int i = start + 1; i < end; i++)
    {
      int key = arr[i];
      int j = i - 1;
      while (j >= start && arr[j] > key)
      {
        arr[j + 1] = arr[j];
        j--;
      }
      arr[j + 1] = key;
    }
  }

  public static int[] ShatterPartition(int[] arr, int start, int length, int num)
  {
    int minV = arr[start];
    int maxV = arr[start];
    for (int i = 1; i < length; i++)
    {
      if (arr[start + i] < minV) minV = arr[start + i];
      if (arr[start + i] > maxV) maxV = arr[start + i];
    }
    int valueRange = maxV - minV + 1;
    int shatters = (length + num - 1) / num;

    List<List<int>> buckets = new List<List<int>>();
    for (int i = 0; i < shatters; i++) buckets.Add(new List<int>());

    for (int i = 0; i < length; i++)
    {
      int v = arr[start + i];
      int idx = (v - minV) * shatters / valueRange;
      if (idx > shatters - 1) idx = shatters - 1;
      buckets[idx].Add(v);
    }

    int[] offsets = new int[shatters + 1];
    for (int i = 0; i < shatters; i++) offsets[i + 1] = offsets[i] + buckets[i].Count;

    int pos = start;
    for (int i = 0; i < shatters; i++)
    {
      foreach (int v in buckets[i]) arr[pos++] = v;
    }
    return offsets;
  }

  public static void ShatterSortRange(int[] arr, int length, int num)
  {
    int[] offsets = ShatterPartition(arr, 0, length, num);
    for (int i = 0; i < offsets.Length - 1; i++)
    {
      if (offsets[i + 1] - offsets[i] > 1) InsertionSort(arr, offsets[i], offsets[i + 1]);
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    ShatterSortRange(arr, n, 4);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}