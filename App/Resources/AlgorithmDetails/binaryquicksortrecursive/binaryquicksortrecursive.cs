using System;

public class BinaryQuickSortRecursive
{
  private static int MostSignificantBit(int value)
  {
    if (value == 0) return -1;
    int bit = 0;
    while ((value >> (bit + 1)) != 0) bit++;
    return bit;
  }

  private static int Partition(int[] arr, int p, int r, int bit)
  {
    int i = p - 1;
    int j = r + 1;
    while (true)
    {
      do
      {
        i++;
      } while (i <= r && ((arr[i] >> bit) & 1) == 0);
      do
      {
        j--;
      } while (j >= p && ((arr[j] >> bit) & 1) == 1);
      if (i < j)
      {
        (arr[i], arr[j]) = (arr[j], arr[i]);
      }
      else
      {
        return j;
      }
    }
  }

  private static void BinaryQuickSort(int[] arr, int p, int r, int bit)
  {
    if (p < r && bit >= 0)
    {
      int q = Partition(arr, p, r, bit);
      BinaryQuickSort(arr, p, q, bit - 1);
      BinaryQuickSort(arr, q + 1, r, bit - 1);
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    int maxValue = arr[0];
    for (int i = 1; i < n; i++)
    {
      if (arr[i] > maxValue) maxValue = arr[i];
    }
    int bit = MostSignificantBit(maxValue);
    BinaryQuickSort(arr, 0, n - 1, bit);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
