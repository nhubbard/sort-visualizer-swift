using System;

public class CocktailBogoSort
{
  public static Random r = new Random();

  public static bool IsMinimum(int[] arr, int start, int end)
  {
    for (int k = start + 1; k < end; k++)
    {
      if (arr[start] > arr[k])
      {
        return false;
      }
    }
    return true;
  }

  public static bool IsMaximum(int[] arr, int start, int end)
  {
    for (int k = start; k < end - 1; k++)
    {
      if (arr[k] > arr[end - 1])
      {
        return false;
      }
    }
    return true;
  }

  public static void ShuffleRange(int[] arr, int start, int end)
  {
    for (int i = start; i < end - 1; i++)
    {
      int j = r.Next(i, end);
      (arr[i], arr[j]) = (arr[j], arr[i]);
    }
  }

  public static void Sort(int[] arr)
  {
    int lo = 0;
    int hi = arr.Length;
    while (lo < hi - 1)
    {
      if (IsMinimum(arr, lo, hi))
      {
        lo++;
      }
      else if (IsMaximum(arr, lo, hi))
      {
        hi--;
      }
      else
      {
        ShuffleRange(arr, lo, hi);
      }
    }
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
