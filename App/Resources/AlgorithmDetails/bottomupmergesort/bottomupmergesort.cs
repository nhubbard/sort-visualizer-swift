using System;

public class BottomUpMergeSort
{
  private static int Merge(int[] array, int[] scratch, int n, int index, int mergeSize)
  {
    int mid = index + mergeSize / 2;
    int end = Math.Min(n, index + mergeSize);
    if (mid >= end) return index;
    int left = index, right = mid, output = index;
    while (left < mid && right < end)
      scratch[output++] = array[left] <= array[right] ? array[left++] : array[right++];
    while (left < mid) scratch[output++] = array[left++];
    while (right < end) scratch[output++] = array[right++];
    return -1;
  }

  public static void Sort(int[] array)
  {
    int n = array.Length;
    if (n < 2) return;
    int[] scratch = (int[])array.Clone();
    int mergeSize = 2;
    while (mergeSize <= n)
    {
      int copyLength = n;
      for (int index = 0; index < n; index += mergeSize)
      {
        int stop = Merge(array, scratch, n, index, mergeSize);
        if (stop >= 0) copyLength = stop;
      }
      Array.Copy(scratch, array, copyLength);
      mergeSize *= 2;
    }
    if (mergeSize / 2 != n)
    {
      int stop = Merge(array, scratch, n, 0, mergeSize);
      Array.Copy(scratch, array, stop < 0 ? n : stop);
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