using System;

public class FlashSort
{
  private static int Classify(int value, int minValue, double c)
  {
    return (int)((value - minValue) * c) + 1;
  }

  private static void DoFlashSort(int[] array)
  {
    var n = array.Length;
    if (n == 0)
      return;

    var m = (int)(0.2 * n) + 2;

    var minValue = array[0];
    var maxValue = array[0];
    var maxIndex = 0;

    var i = 1;
    while (i < n - 1)
    {
      int small,
        big,
        bigIndex;
      if (array[i] < array[i + 1])
      {
        small = array[i];
        big = array[i + 1];
        bigIndex = i + 1;
      }
      else
      {
        big = array[i];
        bigIndex = i;
        small = array[i + 1];
      }
      if (big > maxValue)
      {
        maxValue = big;
        maxIndex = bigIndex;
      }
      if (small < minValue)
      {
        minValue = small;
      }
      i += 2;
    }

    var last = array[n - 1];
    if (last < minValue)
    {
      minValue = last;
    }
    else if (last > maxValue)
    {
      maxValue = last;
      maxIndex = n - 1;
    }

    if (maxValue == minValue)
      return;

    var L = new int[m + 1];
    var c = (m - 1.0) / (maxValue - minValue);

    for (var h = 0; h < n; h++)
    {
      var k = Classify(array[h], minValue, c);
      L[k] += 1;
    }

    for (var k = 2; k <= m; k++)
    {
      L[k] += L[k - 1];
    }

    (array[maxIndex], array[0]) = (array[0], array[maxIndex]);

    var j = 0;
    var kk = m;
    var numMoves = 0;
    while (numMoves < n)
    {
      while (j >= L[kk])
      {
        j++;
        kk = Classify(array[j], minValue, c);
      }

      var evicted = array[j];
      while (j < L[kk])
      {
        kk = Classify(evicted, minValue, c);
        var location = L[kk] - 1;
        var temp = array[location];
        array[location] = evicted;
        evicted = temp;
        L[kk] -= 1;
        numMoves++;
      }
    }

    for (var idx = 1; idx < n; idx++)
    {
      var current = array[idx];
      var pos = idx - 1;
      while (pos >= 0 && array[pos] > current)
      {
        array[pos + 1] = array[pos];
        pos--;
      }
      array[pos + 1] = current;
    }
  }

  public static int[] Sort(int[] array)
  {
    DoFlashSort(array);
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
