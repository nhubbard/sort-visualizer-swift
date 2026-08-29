using System;

public class OptimizedWeaveMergeSort
{
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

  private static void MultiSwap(int[] array, int a, int b, int len)
  {
    for (var i = 0; i < len; i++)
    {
      (array[a + i], array[b + i]) = (array[b + i], array[a + i]);
    }
  }

  private static void Rotate(int[] array, int a, int m, int b)
  {
    var l = m - a;
    var r = b - m;
    while (l > 0 && r > 0)
    {
      if (r < l)
      {
        MultiSwap(array, m - r, m, r);
        b -= r;
        m -= r;
        l -= r;
      }
      else
      {
        MultiSwap(array, a, m, l);
        a += l;
        m += l;
        r -= l;
      }
    }
  }

  private static void BitReversal(int[] array, int a, int b)
  {
    var len = b - a;
    var m = 0;
    var d1 = len >> 1;
    var d2 = d1 + (d1 >> 1);
    var i = 1;
    while (i < len - 1)
    {
      var j = d1;
      var k = i;
      var nn = d2;
      while ((k & 1) == 0)
      {
        j -= nn;
        k >>= 1;
        nn >>= 1;
      }
      m += j;
      if (m > i)
      {
        (array[a + i], array[a + m]) = (array[a + m], array[a + i]);
      }
      i++;
    }
  }

  private static void WeaveInsert(int[] array, int a, int b, bool rightInit)
  {
    var right = rightInit;
    var i = a;
    var j = a + 1;
    while (j < b)
    {
      if (right)
      {
        while (i < j && array[i] <= array[j]) i++;
      }
      else
      {
        while (i < j && array[i] < array[j]) i++;
      }
      if (i == j)
      {
        right = !right;
        j++;
      }
      else
      {
        InsertTo(array, j, i);
        i++;
        j += 2;
      }
    }
  }

  private static void WeaveMerge(int[] array, int a, int mInit, int b)
  {
    if (b - a < 2) return;
    var a1 = a;
    var b1 = b;
    var right = true;
    if ((b - a) % 2 == 1)
    {
      if (mInit - a < b - mInit)
      {
        a1 -= 1;
        right = false;
      }
      else
      {
        b1 += 1;
      }
    }
    var e = b1;
    while (e - a1 > 2)
    {
      var m = (a1 + e) / 2;
      var p = 1;
      while (p * 2 <= m - a1) p *= 2;
      Rotate(array, m - p, m, e - p);
      m = e - p;
      var f = m - p;
      BitReversal(array, f, m);
      BitReversal(array, m, e);
      BitReversal(array, f, e);
      e = f;
    }
    WeaveInsert(array, a, b, right);
  }

  public static int[] Sort(int[] array)
  {
    var n = array.Length;
    if (n <= 1) return array;
    var d = 1;
    while (d < n) d <<= 1;
    while (d > 1)
    {
      var i = 0;
      var dec = 0;
      while (i < n)
      {
        var j = i;
        dec += n;
        while (dec >= d)
        {
          dec -= d;
          j++;
        }
        var k = j;
        dec += n;
        while (dec >= d)
        {
          dec -= d;
          k++;
        }
        WeaveMerge(array, i, j, k);
        i = k;
      }
      d /= 2;
    }
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