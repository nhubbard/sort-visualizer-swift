using System;

public class LazierestSort
{
  private static void Reverse(int[] arr, int a, int b)
  {
    b--;
    while (a < b)
    {
      int t = arr[a]; arr[a++] = arr[b]; arr[b--] = t;
    }
  }

  private static void Rotate(int[] arr, int a, int m, int b)
  {
    Reverse(arr, a, m); Reverse(arr, m, b); Reverse(arr, a, b);
  }

  private static int Search(int[] arr, int a, int b, int value, bool upper)
  {
    while (a < b)
    {
      int mid = (a + b) / 2;
      if (value < arr[mid] || (!upper && value == arr[mid])) b = mid;
      else a = mid + 1;
    }
    return a;
  }

  private static int Gallop(int[] arr, int a, int b, int value, bool backwards)
  {
    int step = 1;
    if (backwards)
    {
      while (b - step >= a && value < arr[b - step]) step *= 2;
      return Search(arr, Math.Max(a, b - step + 1), b - step / 2, value, true);
    }
    while (a - 1 + step < b && value > arr[a - 1 + step]) step *= 2;
    return Search(arr, a + step / 2, Math.Min(b, a - 1 + step), value, false);
  }

  private static void Insertion(int[] arr, int a, int b)
  {
    for (int i = a + 1; i < b; i++)
    {
      int value = arr[i], position = Search(arr, a, i, value, true);
      for (int j = i; j > position; j--) arr[j] = arr[j - 1];
      arr[position] = value;
    }
  }

  private static void Forward(int[] arr, int a, int m, int b)
  {
    int i = a, j = m;
    while (i < j && j < b)
    {
      if (arr[i] > arr[j])
      {
        int k = Gallop(arr, j + 1, b, arr[i], false);
        Rotate(arr, i, j, k);
        i += k - j; j = k;
      }
      else i++;
    }
  }

  private static void Backward(int[] arr, int a, int m, int b)
  {
    int i = m - 1, j = b - 1;
    while (j > i && i >= a)
    {
      if (arr[i] > arr[j])
      {
        int k = Gallop(arr, a, i, arr[j], true);
        Rotate(arr, k, i + 1, j + 1);
        j -= i + 1 - k; i = k - 1;
      }
      else j--;
    }
  }

  private static void Merge(int[] arr, int a, int m, int b)
  {
    if (b - m < m - a) Backward(arr, a, m, b);
    else Forward(arr, a, m, b);
  }

  private static void Fragmented(int[] arr, int a, int m, int b, int size)
  {
    int i = a + (m - a) % size;
    while (i < m)
    {
      int j = Gallop(arr, m, b, arr[i], false);
      Rotate(arr, i, m, j);
      int length = j - m, boundary = i;
      i += length; m += length;
      Merge(arr, a, boundary, i);
      a = i; i += size;
    }
    Merge(arr, Math.Max(a, i - size), i, b);
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n <= 16) { Insertion(arr, 0, n); return; }
    int size = 1;
    while (size * size * size < n) size++;
    int group = size * size;
    for (int i = n % size; i <= n; i += size) Insertion(arr, Math.Max(0, i - size), i);
    int index = n - size, end = n;
    while (index > 0)
    {
      if (end - index == group) { end -= group; index -= size; }
      Forward(arr, Math.Max(0, index - size), index, end);
      index -= size;
    }
    for (index = n - group; index > 0; index -= group)
      Fragmented(arr, Math.Max(0, index - group), index, n, size);
  }

  public static void Main(String[] args)
  {
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56,
      10, 2, 95, 46, 21, 74, 6, 38
    };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}