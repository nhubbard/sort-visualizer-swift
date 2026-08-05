using System;

public class IterativeTopDownMergeSort
{
  private static void Merge(int[] array, int low, int mid, int high)
  {
    int[] left = new int[mid - low];
    int[] right = new int[high - mid];
    Array.Copy(array, low, left, 0, left.Length);
    Array.Copy(array, mid, right, 0, right.Length);
    int i = 0,
      j = 0,
      k = low;
    while (i < left.Length && j < right.Length)
    {
      if (left[i] <= right[j])
      {
        array[k] = left[i];
        i++;
      }
      else
      {
        array[k] = right[j];
        j++;
      }
      k++;
    }
    while (i < left.Length)
    {
      array[k] = left[i];
      i++;
      k++;
    }
    while (j < right.Length)
    {
      array[k] = right[j];
      j++;
      k++;
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    int subarrayCount = 1;
    while (subarrayCount < n)
    {
      subarrayCount *= 2;
    }

    while (subarrayCount > 1)
    {
      for (int i = 0; i < subarrayCount; i += 2)
      {
        int low = n * i / subarrayCount;
        int mid = n * (i + 1) / subarrayCount;
        int high = n * (i + 2) / subarrayCount;
        Merge(arr, low, mid, high);
      }
      subarrayCount /= 2;
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