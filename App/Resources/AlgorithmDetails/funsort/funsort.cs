using System;

public class FunSort
{
  public static bool CompositeLess(int[] arr, int[] key, int mid, int i)
  {
    if (arr[mid] < arr[i]) return true;
    if (arr[mid] == arr[i]) return key[mid] < key[i];
    return false;
  }

  public static int BinarySearch(int[] arr, int[] key, int n, int i)
  {
    int start = 0;
    int end = n - 1;
    while (start < end)
    {
      int mid = (start + end) / 2;
      if (CompositeLess(arr, key, mid, i))
      {
        start = mid + 1;
      }
      else
      {
        end = mid;
      }
    }
    return start;
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    int[] key = new int[n];
    for (int i = 0; i < n; i++) key[i] = i;

    for (int i = 1; i < n; i++)
    {
      bool done = false;
      while (!done)
      {
        int pos = BinarySearch(arr, key, n, i);
        if (pos == i)
        {
          done = true;
        }
        else if (i < pos - 1)
        {
          (arr[i], arr[pos - 1]) = (arr[pos - 1], arr[i]);
          (key[i], key[pos - 1]) = (key[pos - 1], key[i]);
        }
        else
        {
          (arr[i], arr[pos]) = (arr[pos], arr[i]);
          (key[i], key[pos]) = (key[pos], key[i]);
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
