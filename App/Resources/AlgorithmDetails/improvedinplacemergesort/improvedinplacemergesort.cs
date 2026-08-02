using System;

public class ImprovedInPlaceMergeSort
{
  private static void Push(int[] arr, int p, int a, int b)
  {
    if (a == b)
    {
      return;
    }
    var temp = arr[p];
    arr[p] = arr[a];
    for (var i = a + 1; i < b; i++)
    {
      arr[i - 1] = arr[i];
    }
    arr[b - 1] = temp;
  }

  private static void Merge(int[] arr, int a, int m, int b)
  {
    var i = a;
    var j = m;
    while (i < m && j < b)
    {
      if (arr[i] > arr[j])
      {
        j++;
      }
      else
      {
        Push(arr, i, m, j);
        i++;
      }
    }
    while (i < m)
    {
      Push(arr, i, m, b);
      i++;
    }
  }

  private static void MergeSort(int[] arr, int a, int b)
  {
    var m = a + (b - a) / 2;
    if (b - a > 2)
    {
      if (b - a > 3)
      {
        MergeSort(arr, a, m);
      }
      MergeSort(arr, m, b);
    }
    Merge(arr, a, m, b);
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    MergeSort(arr, 0, n);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}