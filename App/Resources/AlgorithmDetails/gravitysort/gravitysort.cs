using System;

public class GravitySort
{
  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n == 0)
      return;

    int minValue = arr[0];
    int maxValue = arr[0];
    for (int i = 1; i < n; i++)
    {
      if (arr[i] < minValue)
        minValue = arr[i];
      if (arr[i] > maxValue)
        maxValue = arr[i];
    }
    int ySize = maxValue - minValue + 1;

    int[] x = new int[n];
    int[] y = new int[ySize];

    for (int i = 0; i < n; i++)
    {
      x[i] = arr[i] - minValue;
      y[x[i]]++;
    }

    for (int i = ySize - 1; i > 0; i--)
    {
      y[i - 1] += y[i];
    }

    for (int j = ySize - 1; j >= 0; j--)
    {
      for (int i = 0; i < n; i++)
      {
        int inc = (i >= n - y[j] ? 1 : 0) - (x[i] >= j ? 1 : 0);
        arr[i] += inc;
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
