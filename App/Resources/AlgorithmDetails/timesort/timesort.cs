using System;
using System.Linq;

public class TimeSort
{
  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n <= 1)
    {
      return;
    }

    // Simulate the reporting order that proportional-to-value sleep durations
    // would produce in a jitter-free race: sort by value, ties broken by the
    // original position, i.e. the order the sleeps were originally scheduled.
    var woken = arr
      .Select((value, index) => (value, index))
      .OrderBy(pair => pair.value)
      .ThenBy(pair => pair.index)
      .ToArray();
    for (int i = 0; i < n; i++)
    {
      arr[i] = woken[i].value;
    }

    // Defensive cleanup pass: real scheduling jitter can't be fully trusted,
    // so finish with an ordinary insertion sort no matter what the race produced.
    for (int i = 1; i < n; i++)
    {
      int j = i;
      while (j > 0 && arr[j - 1] > arr[j])
      {
        int t = arr[j - 1];
        arr[j - 1] = arr[j];
        arr[j] = t;
        j--;
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