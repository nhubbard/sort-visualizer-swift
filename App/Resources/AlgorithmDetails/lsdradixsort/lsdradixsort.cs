using System;

public class RadixSort
{
  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    int maxValue = 0;
    foreach (int value in arr)
    {
      if (value > maxValue) maxValue = value;
    }
    int[] output = new int[n];
    int divisor = 1;
    while (true)
    {
      int[] counts = new int[4];
      for (int i = 0; i < n; i++) counts[(arr[i] / divisor) % 4]++;
      for (int digit = 1; digit < 4; digit++) counts[digit] += counts[digit - 1];
      for (int i = n - 1; i >= 0; i--)
      {
        int digit = (arr[i] / divisor) % 4;
        output[--counts[digit]] = arr[i];
      }
      Array.Copy(output, arr, n);
      if (divisor > maxValue / 4) break;
      divisor *= 4;
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
