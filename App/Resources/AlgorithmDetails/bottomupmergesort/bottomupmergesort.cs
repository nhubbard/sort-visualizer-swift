using System;

public class BottomUpMergeSort
{
  private static void Merge(int[] array, int low, int mid, int high)
  {
    int[] left = new int[mid - low];
    int[] right = new int[high - mid];
    Array.Copy(array, low, left, 0, left.Length);
    Array.Copy(array, mid, right, 0, right.Length);
    int i = 0,
      j = 0,
      k = low;
    while (i < left.Length && j < right.Length)
    {
      if (left[i] <= right[j])
      {
        array[k] = left[i];
        i++;
      }
      else
      {
        array[k] = right[j];
        j++;
      }
      k++;
    }
    while (i < left.Length)
    {
      array[k] = left[i];
      i++;
      k++;
    }
    while (j < right.Length)
    {
      array[k] = right[j];
      j++;
      k++;
    }
  }

  public static int[] Sort(int[] array)
  {
    var n = array.Length;
    for (var width = 1; width < n; width *= 2)
    {
      for (var low = 0; low < n; low += 2 * width)
      {
        var mid = Math.Min(low + width, n);
        var high = Math.Min(low + 2 * width, n);
        if (mid < high)
        {
          Merge(array, low, mid, high);
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
