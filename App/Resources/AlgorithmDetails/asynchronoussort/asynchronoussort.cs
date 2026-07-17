using System;

public class AsynchronousSort
{
  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    int[] ext = new int[n];
    Array.Copy(arr, ext, n);
    int minValue = ext[0];
    int maxValue = ext[0];
    for (int k = 0; k < n; k++)
    {
      if (ext[k] < minValue)
        minValue = ext[k];
      if (ext[k] > maxValue)
        maxValue = ext[k];
    }
    maxValue += 1;

    int cur = minValue;
    int i = 0;
    while (i < n)
    {
      for (int j = 0; j < n; j++)
      {
        if (ext[j] <= cur)
        {
          arr[i] = ext[j];
          ext[j] = maxValue;
          i += 1;
        }
      }
      cur += 1;
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
