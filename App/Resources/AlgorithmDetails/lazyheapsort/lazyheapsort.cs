using System;

public class LazyHeapSort
{
  public static void MaxToFront(int[] arr, int a, int b)
  {
    int best = a;
    int i = a + 1;
    while (i < b)
    {
      if (arr[i] > arr[best])
      {
        best = i;
      }
      i++;
    }
    (arr[best], arr[a]) = (arr[a], arr[best]);
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    int s = (int)Math.Sqrt(n - 1) + 1;

    int i = 0;
    while (i < n)
    {
      MaxToFront(arr, i, Math.Min(i + s, n));
      i += s;
    }

    int j = n;
    while (j > 0)
    {
      int best = 0;
      int k = best + s;
      while (k < j)
      {
        if (arr[k] >= arr[best])
        {
          best = k;
        }
        k += s;
      }
      j--;
      (arr[best], arr[j]) = (arr[j], arr[best]);
      MaxToFront(arr, best, Math.Min(best + s, j));
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