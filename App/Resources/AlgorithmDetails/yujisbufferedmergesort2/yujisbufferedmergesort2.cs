using System;

public class YujisBufferedMergeSort2
{
  private static int CeilLog(int n)
  {
    var i = 0;
    while ((1 << i) < n)
    {
      i++;
    }
    return i;
  }

  private static void MultiSwap(int[] array, int a, int b, int len)
  {
    for (var i = 0; i < len; i++)
    {
      (array[a + i], array[b + i]) = (array[b + i], array[a + i]);
    }
  }

  private static void InsertTo(int[] array, int a, int b)
  {
    var temp = array[a];
    while (a > b)
    {
      a--;
      array[a + 1] = array[a];
    }
    array[b] = temp;
  }

  private static int BinarySearch(int[] array, int start, int end, int value, bool left)
  {
    var a = start;
    var b = end;
    while (a < b)
    {
      var m = a + (b - a) / 2;
      var comp = left ? value <= array[m] : value < array[m];
      if (comp)
      {
        b = m;
      }
      else
      {
        a = m + 1;
      }
    }
    return a;
  }

  private static void BinaryInsertion(int[] array, int a, int b)
  {
    var i = a + 1;
    while (i < b)
    {
      var value = array[i];
      InsertTo(array, i, BinarySearch(array, a, i, value, false));
      i++;
    }
  }

  private static int Merge(int[] array, int a, int m, int b, int p)
  {
    var i = a;
    var j = m;
    while (i < m && j < b)
    {
      if (array[i] <= array[j])
      {
        (array[p], array[i]) = (array[i], array[p]);
        p++;
        i++;
      }
      else
      {
        (array[p], array[j]) = (array[j], array[p]);
        p++;
        j++;
      }
    }
    var leftover = 0;
    while (i < m)
    {
      (array[p], array[i]) = (array[i], array[p]);
      p++;
      i++;
    }
    while (j < b)
    {
      (array[p], array[j]) = (array[j], array[p]);
      p++;
      j++;
      leftover++;
    }
    return leftover;
  }

  private static void MergeWithBufStatic(
    int[] array, int a, int m, int b, int p, bool useBinarySearch
  )
  {
    var i = 0;
    var j = m;
    var k = a;
    if (useBinarySearch)
    {
      while (i < m - a && j < b)
      {
        if (array[j] < array[p + i])
        {
          var value = array[p + i];
          var q = BinarySearch(array, j, b, value, true);
          while (j < q)
          {
            (array[k], array[j]) = (array[j], array[k]);
            k++;
            j++;
          }
        }
        (array[k], array[p + i]) = (array[p + i], array[k]);
        k++;
        i++;
      }
      while (i < m - a)
      {
        (array[k], array[p + i]) = (array[p + i], array[k]);
        k++;
        i++;
      }
    }
    else
    {
      while (i < m - a && j < b)
      {
        if (array[p + i] <= array[j])
        {
          (array[k], array[p + i]) = (array[p + i], array[k]);
          k++;
          i++;
        }
        else
        {
          (array[k], array[j]) = (array[j], array[k]);
          k++;
          j++;
        }
      }
      while (i < m - a)
      {
        (array[k], array[p + i]) = (array[p + i], array[k]);
        k++;
        i++;
      }
    }
  }

  private static void MergeSort(int[] array, int a, int p, int length)
  {
    var j = 16;
    var ceilLogValue = CeilLog(length);
    var pos = length > 16 && (ceilLogValue & 1) == 1 ? p : a;

    var i = pos;
    while (i + 16 <= pos + length)
    {
      BinaryInsertion(array, i, i + 16);
      i += 16;
    }
    BinaryInsertion(array, i, pos + length);

    var nxt = pos;
    while (j < length)
    {
      pos = nxt;
      nxt ^= a ^ p;
      var posNext = nxt;

      i = pos;
      while (i + 2 * j <= pos + length)
      {
        Merge(array, i, i + j, i + 2 * j, posNext);
        i += 2 * j;
        posNext += 2 * j;
      }
      if (i + j < pos + length)
      {
        Merge(array, i, i + j, pos + length, posNext);
      }
      else
      {
        while (i < pos + length)
        {
          (array[i], array[posNext]) = (array[posNext], array[i]);
          i++;
          posNext++;
        }
      }
      j *= 2;
    }
  }

  private static void BufferedMerge(int[] array, int a, int b)
  {
    if (b - a <= 16)
    {
      BinaryInsertion(array, a, b);
      return;
    }

    var m = (a + b + 1) / 2;
    MergeSort(array, m, 2 * m - b, b - m);

    var n = (a + m + 1) / 2;
    var limit = (b - a) / 16;
    while (m - a > limit)
    {
      MergeSort(array, 2 * n - m, n, m - n);
      MergeWithBufStatic(array, n, m, b, 2 * n - m, (b - m) / (m - n) >= CeilLog(n - a));
      m = n;
      n = (a + m + 1) / 2;
    }

    BufferedMerge(array, a, m);
    MultiSwap(array, a, b - (m - a), m - a);
    var s = Merge(array, m, b - (m - a), b, a);
    BufferedMerge(array, b - (m - a) - s, b);
  }

  public static int[] Sort(int[] array)
  {
    var n = array.Length;
    if (n <= 1)
    {
      return array;
    }
    BufferedMerge(array, 0, n);
    return array;
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}