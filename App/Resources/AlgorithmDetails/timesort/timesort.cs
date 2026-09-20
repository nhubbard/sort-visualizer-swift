using System;
public class TimeSort
{
  static void MergeSort(int[] scratch, int[] buffer, int lo, int hi)
  {
    if (hi - lo < 2) return;
    int mid = lo + (hi - lo) / 2;
    MergeSort(scratch, buffer, lo, mid); MergeSort(scratch, buffer, mid, hi);
    int left = lo, right = mid, dest = lo;
    while (left < mid && right < hi)
    {
      if (scratch[left] <= scratch[right]) buffer[dest++] = scratch[left++];
      else buffer[dest++] = scratch[right++];
    }
    while (left < mid) buffer[dest++] = scratch[left++];
    while (right < hi) buffer[dest++] = scratch[right++];
    Array.Copy(buffer, lo, scratch, lo, hi - lo);
  }
  public static void Sort(int[] a)
  {
    int n = a.Length; if (n < 2) return;
    int[] scratch = (int[])a.Clone(), buffer = (int[])scratch.Clone();
    MergeSort(scratch, buffer, 0, n); Array.Copy(scratch, a, n);
    for (int i = 1; i < n; i++)
    {
      int j = i;
      while (j > 0 && a[j - 1] > a[j]) { int held = a[j - 1]; a[j - 1] = a[j]; a[j] = held; j--; }
    }
  }
  public static void Main()
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array); Console.WriteLine("[" + string.Join(", ", array) + "]");
  }
}