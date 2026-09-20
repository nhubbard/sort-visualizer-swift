using System;

public class OptimizedDualPivotQuickSort
{
  public static void Sort(int[] array)
  {
    if (array.Length > 1) DualPivot(array, 0, array.Length - 1, 3);
  }

  private static void InsertionSort(int[] array, int left, int right)
  {
    for (int i = left + 1; i <= right; i++)
    {
      int j = i;
      while (j > left && array[j] < array[j - 1])
      {
        (array[j], array[j - 1]) = (array[j - 1], array[j]);
        j--;
      }
    }
  }

  private static void DualPivot(int[] array, int left, int right, int divisor)
  {
    int length = right - left;
    if (length < 27)
    {
      InsertionSort(array, left, right);
      return;
    }
    int third = length / divisor;
    int med1 = Math.Max(left + 1, left + third);
    int med2 = Math.Min(right - 1, right - third);
    if (array[med1] < array[med2])
    {
      (array[med1], array[left]) = (array[left], array[med1]);
      (array[med2], array[right]) = (array[right], array[med2]);
    }
    else
    {
      (array[med1], array[right]) = (array[right], array[med1]);
      (array[med2], array[left]) = (array[left], array[med2]);
    }
    int pivot1 = array[left], pivot2 = array[right];
    int less = left + 1, great = right - 1;
    for (int k = less; k <= great; k++)
    {
      if (array[k] < pivot1)
      {
        (array[k], array[less]) = (array[less], array[k]);
        less++;
      }
      else if (array[k] > pivot2)
      {
        while (k < great && array[great] > pivot2) great--;
        (array[k], array[great]) = (array[great], array[k]);
        great--;
        if (array[k] < pivot1)
        {
          (array[k], array[less]) = (array[less], array[k]);
          less++;
        }
      }
    }
    int dist = great - less;
    if (dist < 13) divisor++;
    (array[less - 1], array[left]) = (array[left], array[less - 1]);
    (array[great + 1], array[right]) = (array[right], array[great + 1]);
    DualPivot(array, left, less - 2, divisor);
    DualPivot(array, great + 2, right, divisor);
    if (dist > length - 13 && pivot1 != pivot2)
    {
      for (int k = less; k <= great; k++)
      {
        if (array[k] == pivot1) { (array[k], array[less]) = (array[less], array[k]); less++; }
        else if (array[k] == pivot2)
        {
          (array[k], array[great]) = (array[great], array[k]); great--;
          if (array[k] == pivot1) { (array[k], array[less]) = (array[less], array[k]); less++; }
        }
      }
    }
    if (pivot1 < pivot2) DualPivot(array, less, great, divisor);
  }

  public static void Main(String[] args)
  {
    int[] array = {
      55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79,
      21, 88, 5, 51, 66, 29, 44, 12, 78, 33, 91, 6, 58, 12
    };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
