using System;

public class CompleteGraphSort
{
  public static void CompSwap(int[] arr, int a, int b)
  {
    if (arr[a] > arr[b])
    {
      (arr[a], arr[b]) = (arr[b], arr[a]);
    }
  }

  public static void Split(int[] arr, int a, int m, int b)
  {
    if (b - a < 2) return;
    int c = 0, len1 = (b - a) / 2;
    bool odd = (b - a) % 2 == 1;
    if (odd)
    {
      if (m - a > b - m) c = a++;
      else c = --b;
    }
    for (int s = 0; s < len1; s++)
    {
      int i = a;
      for (int j = s; j < len1; j++) CompSwap(arr, i++, m + j);
      for (int j = 0; j < s; j++) CompSwap(arr, i++, m + j);
    }
    if (odd)
    {
      if (c < m)
      {
        for (int j = 0; j < len1; j++) CompSwap(arr, c, m + j);
      }
      else
      {
        for (int j = 0; j < len1; j++) CompSwap(arr, a + j, c);
      }
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    int d = 2, end = 1 << (int)(Math.Log(n - 1) / Math.Log(2) + 1);
    while (d <= end)
    {
      int i = 0, dec = 0;
      while (i < n)
      {
        int j = i;
        dec += n;
        while (dec >= d)
        {
          dec -= d;
          j++;
        }
        int k = j;
        dec += n;
        while (dec >= d)
        {
          dec -= d;
          k++;
        }
        Split(arr, i, j, k);
        i = k;
      }
      d *= 2;
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