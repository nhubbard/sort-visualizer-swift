using System;

public class ImprovedBlockSelectionSort
{
  public static int BlockRoot(int n)
  {
    var i = 1;
    while (i * i < n)
    {
      i *= 2;
    }
    return i;
  }

  public static void MultiSwap(int[] arr, int a, int b, int len)
  {
    for (var i = 0; i < len; i++)
    {
      (arr[a + i], arr[b + i]) = (arr[b + i], arr[a + i]);
    }
  }

  public static void Rotate(int[] arr, int a, int m, int b)
  {
    var l = m - a;
    var r = b - m;
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

  public static int SelectRange(int[] arr, int start, int end, int bLen)
  {
    var minIndex = start;
    var a = start + bLen;
    while (a < end)
    {
      if (arr[a] < arr[minIndex])
      {
        minIndex = a;
      }
      else if (arr[a] == arr[minIndex] && arr[a + bLen - 1] < arr[minIndex + bLen - 1])
      {
        minIndex = a;
      }
      a += bLen;
    }
    return minIndex;
  }

  public static void BlockSelect(int[] arr, int a, int m, int b, int bLen)
  {
    var k = a;
    var j = m;
    while (k < m && arr[k] <= arr[m])
    {
      k += bLen;
    }
    if (k == m)
    {
      return;
    }

    var i = m;
    MultiSwap(arr, k, j, bLen);
    k += bLen;
    j += bLen;

    while (k < j && j < b)
    {
      if (arr[i] <= arr[j])
      {
        if (k != i)
        {
          MultiSwap(arr, k, i, bLen);
        }
        k += bLen;
        i = SelectRange(arr, Math.Max(m, k), j, bLen);
      }
      else
      {
        if (i == k)
        {
          i = j;
        }
        if (k != j)
        {
          MultiSwap(arr, k, j, bLen);
        }
        k += bLen;
        j += bLen;
      }
    }

    while (k < j)
    {
      i = SelectRange(arr, k, b, bLen);
      if (k != i)
      {
        MultiSwap(arr, k, i, bLen);
      }
      k += bLen;
    }
  }

  public static int InPlaceMerge(int[] arr, int a, int m, int b)
  {
    var i = a;
    var j = m;
    while (i < j && j < b)
    {
      if (arr[i] > arr[j])
      {
        var k = j + 1;
        while (k < b && arr[i] > arr[k])
        {
          k++;
        }
        Rotate(arr, i, j, k);
        i += k - j;
        j = k;
      }
      else
      {
        i++;
      }
    }
    return i;
  }

  public static void InPlaceMergeBW(int[] arr, int a, int m, int b)
  {
    var i = m - 1;
    var j = b - 1;
    while (j > i && i >= a)
    {
      if (arr[i] > arr[j])
      {
        var k = i - 1;
        while (k >= a && arr[k] > arr[j])
        {
          k--;
        }
        Rotate(arr, k + 1, i + 1, j + 1);
        j -= i - k;
        i = k;
      }
      else
      {
        j--;
      }
    }
  }

  public static void Sort(int[] arr)
  {
    var n = arr.Length;
    if (n <= 1)
    {
      return;
    }
    var j = 1;
    while (j < n)
    {
      var bLen = BlockRoot(j);
      var runLength = j;
      var b = n - n % bLen;

      while (runLength > 16)
      {
        var i = 0;
        while (i + j < b)
        {
          var k = i;
          while (k + runLength < Math.Min(i + 2 * j, b))
          {
            BlockSelect(arr, k, k + runLength, Math.Min(k + 2 * runLength, b), bLen);
            k += runLength;
          }
          i += 2 * j;
        }
        runLength = bLen;
        bLen = BlockRoot(bLen);
      }

      var i2 = 0;
      while (i2 + j < b)
      {
        var k = i2;
        var f = i2;
        while (k + runLength < Math.Min(i2 + 2 * j, b))
        {
          f = InPlaceMerge(arr, f, k + runLength, Math.Min(k + 2 * runLength, b));
          k += runLength;
        }
        i2 += 2 * j;
      }

      InPlaceMergeBW(arr, n - n % (2 * j), b, n);
      j *= 2;
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