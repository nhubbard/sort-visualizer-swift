using System;
public class BubbleBogoSort
{
  public static void Sort(int[] a)
  {
    int n = a.Length; if (n < 2) return;
    bool swapped = true;
    while (swapped)
    {
      swapped = false;
      for (int i = 0; i + 1 < n; i++) if (a[i] > a[i + 1])
      {
        int held = a[i]; a[i] = a[i + 1]; a[i + 1] = held; swapped = true;
      }
    }
  }
  public static void Main()
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23 }; Sort(array);
    Console.WriteLine("[" + string.Join(", ", array) + "]");
  }
}