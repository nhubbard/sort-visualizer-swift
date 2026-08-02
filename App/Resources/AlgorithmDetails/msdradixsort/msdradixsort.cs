using System;
using System.Collections.Generic;

public class MSDRadixSort
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

  private static void RadixMSD(int[] array, int low, int high, int radix, int power)
  {
    if (low >= high || power < 0)
    {
      return;
    }

    var buckets = new List<int>[radix];
    for (var i = 0; i < radix; i++)
    {
      buckets[i] = new List<int>();
    }

    for (var i = low; i < high; i++)
    {
      buckets[GetDigit(array[i], power, radix)].Add(array[i]);
    }

    var index = low;
    foreach (var bucket in buckets)
    {
      foreach (var value in bucket)
      {
        array[index++] = value;
      }
    }

    var start = low;
    foreach (var bucket in buckets)
    {
      RadixMSD(array, start, start + bucket.Count, radix, power - 1);
      start += bucket.Count;
    }
  }

  public static int[] Sort(int[] array)
  {
    if (array.Length <= 1)
    {
      return array;
    }
    var radix = 4;
    var maxValue = array[0];
    foreach (var value in array)
    {
      if (value > maxValue)
      {
        maxValue = value;
      }
    }
    var highestPower = 0;
    var probe = radix;
    while (probe <= maxValue)
    {
      highestPower++;
      probe *= radix;
    }
    RadixMSD(array, 0, array.Length, radix, highestPower);
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