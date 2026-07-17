using System;

public class StableSelectionSort
{
  public static void Sort(int[] array)
  {
    for (int i = 0; i < array.Length - 1; i++)
    {
      int min = i;
      for (int j = i + 1; j < array.Length; j++)
      {
        if (array[j] < array[min])
        {
          min = j;
        }
      }
      int tmp = array[min];
      int pos = min;
      while (pos > i)
      {
        array[pos] = array[pos - 1];
        pos--;
      }
      array[pos] = tmp;
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
