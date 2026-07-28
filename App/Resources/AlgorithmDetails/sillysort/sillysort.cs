using System;

public class SillySort
{
  public static void SillySortRange(int[] arr, int i, int j)
  {
    if (i < j)
    {
      int m = i + (j - i) / 2;
      SillySortRange(arr, i, m);
      SillySortRange(arr, m + 1, j);
      if (arr[i] >= arr[m + 1])
      {
        (arr[i], arr[m + 1]) = (arr[m + 1], arr[i]);
      }
      SillySortRange(arr, i + 1, j);
    }
  }

  public static void Sort(int[] arr)
  {
    SillySortRange(arr, 0, arr.Length - 1);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
