using System;

public class StoogeSort
{
  public static void Sort(int[] arr, int i, int j)
  {
    if (arr[j].CompareTo(arr[i]) < 0)
    {
      (arr[i], arr[j]) = (arr[j], arr[i]);
    }
    if (j - i > 1)
    {
      int t = (j - i + 1) / 3;
      Sort(arr, i, j - t);
      Sort(arr, i + t, j);
      Sort(arr, i, j - t);
    }
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array, 0, array.Length - 1);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
