using System;

public class ClassicGravitySort
{
  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n == 0)
      return;

    int maxValue = arr[0];
    for (int i = 1; i < n; i++)
    {
      if (arr[i] > maxValue)
        maxValue = arr[i];
    }

    int[] transpose = new int[maxValue];

    for (int i = 0; i < n; i++)
    {
      int value = arr[i];
      for (int j = 0; j < value; j++)
      {
        transpose[j]++;
      }
    }

    for (int i = 0; i < n; i++)
    {
      int total = 0;
      for (int j = 0; j < maxValue; j++)
      {
        if (transpose[j] > 0)
          total++;
      }
      arr[n - i - 1] = total;
      for (int j = 0; j < maxValue; j++)
      {
        transpose[j]--;
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