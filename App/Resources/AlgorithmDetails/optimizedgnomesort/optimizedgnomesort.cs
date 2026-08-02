using System;

public class OptimizedGnomeSort
{
  public static int[] Sort(int[] array)
  {
    for (int i = 1; i < array.Length; i++)
    {
      int pos = i;
      while (pos > 0 && array[pos - 1] > array[pos])
      {
        (array[pos - 1], array[pos]) = (array[pos], array[pos - 1]);
        pos--;
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