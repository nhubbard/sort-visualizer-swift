using System;

public class DualPivotQuickSort
{
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
    if (length < 4)
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
    if (great - less < 13) divisor++;
    (array[less - 1], array[left]) = (array[left], array[less - 1]);
    (array[great + 1], array[right]) = (array[right], array[great + 1]);
    DualPivot(array, left, less - 2, divisor);
    if (pivot1 < pivot2) DualPivot(array, less, great, divisor);
    DualPivot(array, great + 2, right, divisor);
  }

  public static int[] Sort(int[] array, int low, int high)
  {
    DualPivot(array, low, high, 3);
    return array;
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array, 0, array.Length - 1);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
