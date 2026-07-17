using System;

public class CocktailMergeSort
{
  public static int MinRunLength(int n)
  {
    int r = 0;
    while (n >= 64)
    {
      r |= n & 1;
      n >>= 1;
    }
    return n + r;
  }

  public static void CocktailShakerSort(int[] array, int start, int end)
  {
    int length = end - start;
    if (length <= 1)
    {
      return;
    }
    int i = 0;
    while (i < length / 2)
    {
      bool isSorted = true;
      int j = i;
      while (j < length - i - 1)
      {
        if (array[start + j] > array[start + j + 1])
        {
          (array[start + j], array[start + j + 1]) = (array[start + j + 1], array[start + j]);
          isSorted = false;
        }
        j++;
      }
      j = length - i - 1;
      while (j > i)
      {
        if (array[start + j - 1] > array[start + j])
        {
          (array[start + j - 1], array[start + j]) = (array[start + j], array[start + j - 1]);
          isSorted = false;
        }
        j--;
      }
      if (isSorted)
      {
        break;
      }
      i++;
    }
  }

  public static void Merge(int[] array, int start, int mid, int end)
  {
    int leftLength = mid - start;
    int rightLength = end - mid;
    int[] left = new int[leftLength];
    int[] right = new int[rightLength];
    Array.Copy(array, start, left, 0, leftLength);
    Array.Copy(array, mid, right, 0, rightLength);
    int i = 0,
      j = 0,
      k = start;
    while (i < leftLength && j < rightLength)
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
    while (i < leftLength)
    {
      array[k] = left[i];
      i++;
      k++;
    }
    while (j < rightLength)
    {
      array[k] = right[j];
      j++;
      k++;
    }
  }

  public static void Sort(int[] array)
  {
    int n = array.Length;
    if (n <= 1)
    {
      return;
    }
    int minRun = MinRunLength(n);
    if (n == minRun)
    {
      CocktailShakerSort(array, 0, n);
      return;
    }
    int i = 0;
    while (i <= n - minRun)
    {
      CocktailShakerSort(array, i, i + minRun);
      i += minRun;
    }
    if (i < n)
    {
      CocktailShakerSort(array, i, n);
    }
    int width = minRun;
    while (width < n)
    {
      i = 0;
      while (i < n)
      {
        int mid = Math.Min(i + width, n);
        int end = Math.Min(i + 2 * width, n);
        if (mid < end)
        {
          Merge(array, i, mid, end);
        }
        i += 2 * width;
      }
      width *= 2;
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
