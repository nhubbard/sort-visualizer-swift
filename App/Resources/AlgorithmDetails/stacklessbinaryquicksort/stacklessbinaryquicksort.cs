using System;

public class StacklessBinaryQuickSort
{
  private static int MostSignificantBit(int value)
  {
    if (value == 0) return -1;
    int bit = 0;
    while ((value >> (bit + 1)) != 0) bit++;
    return bit;
  }

  private static bool GetBit(int value, int bit)
  {
    return ((value >> bit) & 1) != 0;
  }

  private static int Partition(int[] arr, int lo, int hi, int bit)
  {
    int i = lo - 1;
    int j = hi;
    while (true)
    {
      i++;
      while (i < j && !GetBit(arr[i], bit)) i++;
      j--;
      while (j > i && GetBit(arr[j], bit)) j--;
      if (i < j)
      {
        (arr[i], arr[j]) = (arr[j], arr[i]);
      }
      else
      {
        return i;
      }
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n <= 1) return;

    int maxValue = arr[0];
    foreach (var value in arr)
    {
      if (value > maxValue) maxValue = value;
    }

    int q = MostSignificantBit(maxValue);
    if (q < 0) return;

    int m = 0;
    int i = 0;
    int b = n;

    while (i < n)
    {
      int p = (b - i < 1) ? i : Partition(arr, i, b, q);

      if (q == 0)
      {
        m += 2;
        while (!GetBit(m, q + 1)) q++;
        i = b;
        while (b < n && (arr[b] >> (q + 1)) == (m >> (q + 1))) b++;
      }
      else
      {
        b = p;
        q--;
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