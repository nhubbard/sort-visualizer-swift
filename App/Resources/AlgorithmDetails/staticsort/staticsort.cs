using System;

public class StaticSort
{
  private static (int min, int max) FindMinMax(int[] array, int a, int b)
  {
    var minValue = array[a];
    var maxValue = array[a];
    for (var i = a + 1; i < b; i++)
    {
      if (array[i] < minValue)
      {
        minValue = array[i];
      }
      else if (array[i] > maxValue)
      {
        maxValue = array[i];
      }
    }
    return (minValue, maxValue);
  }

  private static void InsertionSortRange(int[] array, int s, int e)
  {
    for (var i = s + 1; i < e; i++)
    {
      var j = i;
      while (j > s && array[j - 1] > array[j])
      {
        (array[j - 1], array[j]) = (array[j], array[j - 1]);
        j--;
      }
    }
  }

  private static void SiftDown(int[] array, int s, int root, int size)
  {
    while (true)
    {
      var largest = root;
      var left = 2 * root + 1;
      var right = 2 * root + 2;
      if (left < size && array[s + largest] < array[s + left])
      {
        largest = left;
      }
      if (right < size && array[s + largest] < array[s + right])
      {
        largest = right;
      }
      if (largest == root)
        break;
      (array[s + root], array[s + largest]) = (array[s + largest], array[s + root]);
      root = largest;
    }
  }

  private static void HeapSortRange(int[] array, int s, int e)
  {
    var size = e - s;
    if (size <= 1)
      return;
    var i = size / 2 - 1;
    while (i >= 0)
    {
      SiftDown(array, s, i, size);
      i--;
    }
    var end = size - 1;
    while (end > 0)
    {
      (array[s], array[s + end]) = (array[s + end], array[s]);
      SiftDown(array, s, 0, end);
      end--;
    }
  }

  private static int Classify(int value, int minValue, double c)
  {
    return (int)((value - minValue) * c);
  }

  private static void DoStaticSort(int[] array, int a, int b)
  {
    var (minValue, maxValue) = FindMinMax(array, a, b);
    var auxLen = b - a;
    var count = new int[auxLen + 1];
    var offset = new int[auxLen + 1];
    var c = (double)auxLen / (maxValue - minValue + 1);

    for (var i = a; i < b; i++)
    {
      var idx = Classify(array[i], minValue, c);
      count[idx] += 1;
    }

    offset[0] = a;
    for (var i = 1; i < auxLen; i++)
    {
      offset[i] = count[i - 1] + offset[i - 1];
    }

    for (var v = 0; v < auxLen; v++)
    {
      while (count[v] > 0)
      {
        var origin = offset[v];
        var from = origin;
        var num = array[from];
        array[from] = -1;
        do
        {
          var idx = Classify(num, minValue, c);
          var to = offset[idx];
          offset[idx] += 1;
          count[idx] -= 1;
          var temp = array[to];
          array[to] = num;
          num = temp;
          from = to;
        } while (from != origin);
      }
    }

    for (var i = 0; i < auxLen; i++)
    {
      var s = (i > 1) ? offset[i - 1] : a;
      var e = offset[i];
      if (e - s <= 1)
        continue;
      if (e - s > 16)
      {
        HeapSortRange(array, s, e);
      }
      else
      {
        InsertionSortRange(array, s, e);
      }
    }
  }

  public static int[] Sort(int[] array)
  {
    if (array.Length > 1)
    {
      DoStaticSort(array, 0, array.Length);
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
