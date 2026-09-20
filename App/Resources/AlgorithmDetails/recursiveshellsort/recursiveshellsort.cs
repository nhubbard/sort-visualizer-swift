using System;

public class RecursiveShellSort
{
  private static void GappedInsertionSort(int[] array, int a, int b, int gap)
  {
    for (var i = a + gap; i < b; i += gap)
    {
      var j = i;
      while (j - gap >= a && array[j] < array[j - gap])
      {
        var temp = array[j];
        array[j] = array[j - gap];
        array[j - gap] = temp;
        j -= gap;
      }
    }
  }

  public static void Sort(int[] array, int start, int end, int g)
  {
    if (start + g <= end)
    {
      Sort(array, start, end, 3 * g);
      Sort(array, start + g, end, 3 * g);
      Sort(array, start + (2 * g), end, 3 * g);
      GappedInsertionSort(array, start, end, g);
    }
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array, 0, array.Length, 1);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}