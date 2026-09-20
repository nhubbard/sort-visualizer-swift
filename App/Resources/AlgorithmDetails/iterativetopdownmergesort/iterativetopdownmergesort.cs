using System;

public class IterativeTopDownMergeSort
{
  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n < 2) return;
    int[] scratch = new int[n];
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
        Merge(arr, scratch, low, mid, high);
      }
      subarrayCount /= 2;
    }
  }

  private static void Merge(int[] array, int[] scratch, int low, int mid, int high)
  {
    int left = low, right = mid, output = low;
    while (left < mid && right < high)
    {
      if (array[left] <= array[right])
      {
        scratch[output++] = array[left++];
      }
      else
      {
        scratch[output++] = array[right++];
      }
    }
    while (left < mid) scratch[output++] = array[left++];
    while (right < high) scratch[output++] = array[right++];
    for (int i = low; i < high; i++) array[i] = scratch[i];
  }

  public static void Main(String[] args)
  {
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56
    };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
