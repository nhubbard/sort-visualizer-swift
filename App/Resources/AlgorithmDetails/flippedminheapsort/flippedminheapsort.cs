using System;

public class FlippedMinHeapSort
{
  public static int Idx(int p, int n)
  {
    return n - p;
  }

  public static void SiftDown(int[] arr, int root, int dist, int n)
  {
    while (root <= dist / 2)
    {
      int leaf = 2 * root;
      if (leaf < dist && arr[Idx(leaf, n)] > arr[Idx(leaf + 1, n)])
      {
        leaf += 1;
      }
      if (arr[Idx(root, n)] > arr[Idx(leaf, n)])
      {
        (arr[Idx(root, n)], arr[Idx(leaf, n)]) = (arr[Idx(leaf, n)], arr[Idx(root, n)]);
        root = leaf;
      }
      else
      {
        break;
      }
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;

    int i = n / 2;
    while (i >= 1)
    {
      SiftDown(arr, i, n, n);
      i -= 1;
    }

    i = n;
    while (i > 1)
    {
      (arr[Idx(1, n)], arr[Idx(i, n)]) = (arr[Idx(i, n)], arr[Idx(1, n)]);
      SiftDown(arr, 1, i - 1, n);
      i -= 1;
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