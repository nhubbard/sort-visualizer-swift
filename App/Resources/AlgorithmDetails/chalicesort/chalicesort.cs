using System;

public class ChaliceSort
{
  public static int[] Sort(int[] array)
  {
    RotateMergeSortRange(array, 0, array.Length);
    return array;
  }

  private static void MultiSwap(int[] arr, int a, int b, int len)
  {
    for (int i = 0; i < len; i++)
    {
      int t = arr[a + i];
      arr[a + i] = arr[b + i];
      arr[b + i] = t;
    }
  }

  private static void Rotate(int[] arr, int a, int m, int b)
  {
    int l = m - a,
      r = b - m;
    while (l > 0 && r > 0)
    {
      if (r < l)
      {
        MultiSwap(arr, m - r, m, r);
        b -= r;
        m -= r;
        l -= r;
      }
      else
      {
        MultiSwap(arr, a, m, l);
        a += l;
        m += l;
        r -= l;
      }
    }
  }

  private static int BinarySearch(int[] arr, int a, int b, int value, bool left)
  {
    while (a < b)
    {
      int mid = a + (b - a) / 2;
      bool comp = left ? value <= arr[mid] : value < arr[mid];
      if (comp)
      {
        b = mid;
      }
      else
      {
        a = mid + 1;
      }
    }
    return a;
  }

  private static int BufferLimit(int length)
  {
    int cubeRoot = 1;
    while (cubeRoot * cubeRoot * cubeRoot < length / 4) cubeRoot *= 2;
    return 4 * cubeRoot;
  }

  private static void RotateMerge(int[] arr, int a, int m, int b)
  {
    if (m - a <= BufferLimit(b - a) && b - m <= BufferLimit(b - a))
    {
      int[] temp = new int[b - a];
      Array.Copy(arr, a, temp, 0, b - a);
      int i = 0, j = m - a;
      for (int k = a; k < b; k++)
      {
        if (i < m - a && (j == b - a || temp[i] <= temp[j])) arr[k] = temp[i++];
        else arr[k] = temp[j++];
      }
      return;
    }
    int m1,
      m2,
      m3;
    if (m - a >= b - m)
    {
      m1 = a + (m - a) / 2;
      int value = arr[m1];
      m2 = BinarySearch(arr, m, b, value, true);
      m3 = m1 + (m2 - m);
    }
    else
    {
      m2 = m + (b - m) / 2;
      int value = arr[m2];
      m1 = BinarySearch(arr, a, m, value, false);
      m3 = m2 - (m - m1);
      m2 = m2 + 1;
    }
    Rotate(arr, m1, m, m2);
    if (m2 - (m3 + 1) > 0 && b - m2 > 0)
    {
      RotateMerge(arr, m3 + 1, m2, b);
    }
    if (m1 - a > 0 && m3 - m1 > 0)
    {
      RotateMerge(arr, a, m1, m3);
    }
  }

  private static void RotateMergeSortRange(int[] arr, int a, int b)
  {
    int len = b - a;
    for (int start = a; start < b; start += 32)
    {
      int end = Math.Min(start + 32, b);
      for (int i = start + 1; i < end; i++)
      {
        int value = arr[i], j = i;
        while (j > start && arr[j - 1] > value) { arr[j] = arr[j - 1]; j--; }
        arr[j] = value;
      }
    }
    for (int j = 32; j < len; j *= 2)
    {
      int i;
      for (i = a; i + 2 * j <= b; i += 2 * j)
      {
        RotateMerge(arr, i, i + j, i + 2 * j);
      }
      if (i + j < b)
      {
        RotateMerge(arr, i, i + j, b);
      }
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
