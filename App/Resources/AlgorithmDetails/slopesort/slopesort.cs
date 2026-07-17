using System;

public class SlopeSort
{
  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    for (int start = 1; start < n; start++)
    {
      int i = start;
      int k = start - 1;
      while (k >= 0)
      {
        if (arr[i] < arr[k])
        {
          (arr[i], arr[k]) = (arr[k], arr[i]);
        }
        k--;
        i--;
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
