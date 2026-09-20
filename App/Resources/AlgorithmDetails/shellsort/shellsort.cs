using System;

public class ShellSort
{
  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    int[] gaps = { 8861, 3938, 1750, 701, 301, 132, 57, 23, 10, 4, 1 };
    foreach (int gap in gaps)
    {
      if (gap >= n) continue;
      for (var i = gap; i < n; i++)
      {
        var j = i;
        while (j >= gap && arr[j] < arr[j - gap])
        {
          (arr[j], arr[j - gap]) = (arr[j - gap], arr[j]);
          j -= gap;
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
