using System;

public class BottomUpHeapSort
{
  public static void SiftDown(int[] arr, int i, int b)
  {
    int j = i;
    while (2 * j + 1 < b)
    {
      if (2 * j + 2 < b)
      {
        j = (arr[2 * j + 2] > arr[2 * j + 1]) ? 2 * j + 2 : 2 * j + 1;
      }
      else
      {
        j = 2 * j + 1;
      }
    }
    while (arr[i] > arr[j])
    {
      j = (j - 1) / 2;
    }
    while (j > i)
    {
      (arr[i], arr[j]) = (arr[j], arr[i]);
      j = (j - 1) / 2;
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    for (int i = (n - 1) / 2; i >= 0; i--)
    {
      SiftDown(arr, i, n);
    }
    for (int i = n - 1; i > 0; i--)
    {
      (arr[0], arr[i]) = (arr[i], arr[0]);
      SiftDown(arr, 0, i);
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