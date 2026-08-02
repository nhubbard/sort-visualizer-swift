using System;
using System.Linq;

public class IndexSort
{
  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    int minValue = arr.Min();

    for (int i = 0; i < n; i++)
    {
      int cmpCount = 0;
      while (arr[i] - minValue != i && cmpCount < n)
      {
        int j = arr[i] - minValue;
        (arr[i], arr[j]) = (arr[j], arr[i]);
        cmpCount++;
      }
      if (cmpCount >= n - 1)
      {
        break;
      }
    }
  }

  public static void Main(String[] args)
  {
    int[] array = { 7, 3, 14, 0, 9, 5, 12, 1, 15, 4, 10, 2, 13, 6, 11, 8 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}