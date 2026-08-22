using System;

public class HybridCombSort
{
  public static void InsertionSort(int[] arr)
  {
    int n = arr.Length;
    for (int i = 1; i < n; i++)
    {
      int key = arr[i];
      int j = i - 1;
      while (j >= 0 && arr[j] > key)
      {
        arr[j + 1] = arr[j];
        j = j - 1;
      }
      arr[j + 1] = key;
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    double shrink = 1.3;
    int gap = n;
    bool sorted = false;
    int threshold = Math.Min(8, n / 32);
    while (!sorted)
    {
      gap = (int)Math.Floor(gap / shrink);
      if (gap <= 1)
      {
        sorted = true;
        gap = 1;
      }
      for (int i = 0; i < n - gap; i++)
      {
        if (gap <= threshold)
        {
          InsertionSort(arr);
          return;
        }
        int sm = gap + i;
        if (arr[i] > arr[sm])
        {
          (arr[i], arr[sm]) = (arr[sm], arr[i]);
          sorted = false;
        }
      }
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