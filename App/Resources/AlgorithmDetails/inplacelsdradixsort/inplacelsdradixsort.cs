using System;

public class InPlaceLSDRadixSort
{
  private static int IntPow(int b, int exponent)
  {
    var result = 1;
    for (var i = 0; i < exponent; i++)
    {
      result *= b;
    }
    return result;
  }

  private static int GetDigit(int value, int power, int radix)
  {
    return (value / IntPow(radix, power)) % radix;
  }

  private static void MultiSwap(int[] arr, int pos, int to)
  {
    if (to > pos)
    {
      for (var k = pos; k < to; k++)
      {
        (arr[k], arr[k + 1]) = (arr[k + 1], arr[k]);
      }
    }
    else if (to < pos)
    {
      for (var k = pos; k > to; k--)
      {
        (arr[k], arr[k - 1]) = (arr[k - 1], arr[k]);
      }
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n == 0)
    {
      return;
    }
    var radix = 4;
    var maxValue = arr[0];
    foreach (var value in arr)
    {
      if (value > maxValue)
      {
        maxValue = value;
      }
    }

    var maxPower = 0;
    var probe = radix;
    while (probe <= maxValue)
    {
      maxPower++;
      probe *= radix;
    }

    var vregs = new int[radix - 1];

    for (var power = 0; power <= maxPower; power++)
    {
      for (var i = 0; i < vregs.Length; i++)
      {
        vregs[i] = n - 1;
      }

      var pos = 0;
      for (var step = 0; step < n; step++)
      {
        var digit = GetDigit(arr[pos], power, radix);
        if (digit == 0)
        {
          pos++;
        }
        else
        {
          var to = vregs[digit - 1];
          MultiSwap(arr, pos, to);
          for (var j = digit - 1; j > 0; j--)
          {
            vregs[j - 1]--;
          }
        }
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