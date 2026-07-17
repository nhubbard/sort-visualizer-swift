using System;

public class ClassicThreeSmoothCombSort
{
  private static bool Is3Smooth(int n)
  {
    while (n % 6 == 0)
    {
      n /= 6;
    }
    while (n % 3 == 0)
    {
      n /= 3;
    }
    while (n % 2 == 0)
    {
      n /= 2;
    }
    return n == 1;
  }

  public static void Sort(int[] arr)
  {
    int length = arr.Length;
    for (int g = length - 1; g > 0; g--)
    {
      if (Is3Smooth(g))
      {
        for (int i = g; i < length; i++)
        {
          if (arr[i - g] > arr[i])
          {
            int t = arr[i - g];
            arr[i - g] = arr[i];
            arr[i] = t;
          }
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
