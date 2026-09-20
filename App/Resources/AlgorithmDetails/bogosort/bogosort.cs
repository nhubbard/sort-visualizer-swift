using System;
public class BogoSort
{
  static void Reverse(int[] a, int low, int high)
  {
    while (low < high) { int held = a[low]; a[low] = a[high]; a[high] = held; low++; high--; }
  }
  public static void Sort(int[] a)
  {
    int n = a.Length; if (n < 2) return;
    bool ordered = true; for (int i = 1; i < n; i++) if (a[i] < a[i - 1]) { ordered = false; break; }
    if (ordered) return;
    while (true)
    {
      int pivot = n - 2;
      while (pivot >= 0 && a[pivot] >= a[pivot + 1]) pivot--;
      if (pivot < 0) break;
      int successor = n - 1;
      while (a[successor] <= a[pivot]) successor--;
      int held = a[pivot]; a[pivot] = a[successor]; a[successor] = held;
      Reverse(a, pivot + 1, n - 1);
    }
    Reverse(a, 0, n - 1);
  }
  public static void Main()
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23 }; Sort(array);
    Console.WriteLine("[" + string.Join(", ", array) + "]");
  }
}