using System;

public class BurntPancakeSort
{
  public static void Flip(int[] arr, int end)
  {
    var start = 0;
    while (start < end)
    {
      (arr[start], arr[end]) = (arr[end], arr[start]);
      start++;
      end--;
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    for (var i = n - 1; i > 0; i--)
    {
      var max = 0;
      for (var j = max + 1; j <= i; j++)
      {
        if (arr[j] > arr[max])
        {
          max = j;
        }
      }
      if (max != i)
      {
        Flip(arr, max);
        Flip(arr, i);
        Flip(arr, i - 1);
        Flip(arr, max - 1);
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