using System;

public class OptimizedBubbleSort
{
  public static int[] Sort(int[] array)
  {
    int i = array.Length - 1;
    while (i > 0)
    {
      int consecSorted = 1;
      for (int j = 0; j < i; j++)
      {
        if (array[j] > array[j + 1])
        {
          (array[j], array[j + 1]) = (array[j + 1], array[j]);
          consecSorted = 1;
        }
        else
        {
          consecSorted++;
        }
      }
      i -= consecSorted;
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