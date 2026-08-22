using System;
using System.Linq;

public class CountingSort
{
  public static int[] Sort(int[] array)
  {
    int max = array.Max();
    var counts = new int[max + 1];
    foreach (var value in array)
    {
      counts[value]++;
    }
    for (var i = 1; i <= max; i++)
    {
      counts[i] += counts[i - 1];
    }

    var output = new int[array.Length];
    for (var i = array.Length - 1; i >= 0; i--)
    {
      counts[array[i]]--;
      output[counts[array[i]]] = array[i];
    }
    return output;
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    array = Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}