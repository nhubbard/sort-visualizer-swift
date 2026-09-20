using System;

public class InsertionSort
{
  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    for (int i = 1; i < n; i++)
    {
      int j = i;
      while (j > 0 && arr[j - 1] > arr[j])
      {
        (arr[j], arr[j - 1]) = (arr[j - 1], arr[j]);
        j--;
      }
    }
  }

  public static void Main(String[] args)
  {
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56
    };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
