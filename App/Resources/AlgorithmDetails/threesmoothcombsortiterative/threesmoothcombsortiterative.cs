using System;

public class ThreeSmoothCombSortIterative
{
  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n <= 1)
    {
      return;
    }
    int pow2 = (int)(Math.Log(n - 1) / Math.Log(2));
    for (int k = pow2; k >= 0; k--)
    {
      int pow3 = (int)((Math.Log(n) - k * Math.Log(2)) / Math.Log(3));
      for (int j = pow3; j >= 0; j--)
      {
        int gap = (int)(Math.Pow(2, k) * Math.Pow(3, j));
        for (int i = 0; i + gap < n; i++)
        {
          if (arr[i] > arr[i + gap])
          {
            int t = arr[i];
            arr[i] = arr[i + gap];
            arr[i + gap] = t;
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
