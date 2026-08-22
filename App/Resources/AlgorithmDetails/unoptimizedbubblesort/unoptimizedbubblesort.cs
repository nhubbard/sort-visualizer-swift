using System;

public class UnoptimizedBubbleSort
{
  public static int[] Sort(int[] array)
  {
    bool sorted = false;
    while (!sorted)
    {
      sorted = true;
      for (int i = 0; i < array.Length - 1; i++)
      {
        if (array[i] > array[i + 1])
        {
          (array[i], array[i + 1]) = (array[i + 1], array[i]);
          sorted = false;
        }
      }
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