using System;

public class SmartBogoBogoSort
{
  public static Random r = new Random();

  public static void Sort(int[] arr, int length)
  {
    if (length == 1)
    {
      return;
    }
    Sort(arr, length - 1);
    while (arr[length - 2] > arr[length - 1])
    {
      for (int i = length - 1; i > 0; i--)
      {
        int j = r.Next(i + 1);
        (arr[i], arr[j]) = (arr[j], arr[i]);
      }
      Sort(arr, length - 1);
    }
  }

  public static void Sort(int[] arr)
  {
    Sort(arr, arr.Length);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 14, 23 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}