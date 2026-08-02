using System;

public class DoubleSelectionSort
{
  public static void SortInPlace(int[] array)
  {
    int n = array.Length;
    if (n <= 1)
    {
      return;
    }

    var left = 0;
    var right = n - 1;
    var smallest = 0;
    var biggest = 0;

    while (left <= right)
    {
      for (var i = left; i <= right; i++)
      {
        if (array[i] > array[biggest])
        {
          biggest = i;
        }
        if (array[i] < array[smallest])
        {
          smallest = i;
        }
      }

      if (biggest == left)
      {
        biggest = smallest;
      }

      (array[left], array[smallest]) = (array[smallest], array[left]);
      (array[right], array[biggest]) = (array[biggest], array[right]);

      left++;
      right--;
      smallest = left;
      biggest = right;
    }
  }

  public static int[] Sort(int[] array)
  {
    SortInPlace(array);
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