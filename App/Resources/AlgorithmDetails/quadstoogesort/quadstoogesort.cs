using System;

public class QuadStoogeSort
{
  public static void QuadStooge(int[] arr, int pos, int length)
  {
    if (length >= 2 && arr[pos] > arr[pos + length - 1])
    {
      (arr[pos], arr[pos + length - 1]) = (arr[pos + length - 1], arr[pos]);
    }
    if (length <= 2)
    {
      return;
    }

    int len1 = length / 2;
    int len2 = (length + 1) / 2;
    int len3 = (len1 + 1) / 2 + (len2 + 1) / 2;

    QuadStooge(arr, pos, len1);
    QuadStooge(arr, pos + len1, len2);
    QuadStooge(arr, pos + len1 / 2, len3);
    QuadStooge(arr, pos + len1, len2);
    QuadStooge(arr, pos, len1);
    if (length > 3)
    {
      QuadStooge(arr, pos + len1 / 2, len3);
    }
  }

  public static void Sort(int[] arr)
  {
    QuadStooge(arr, 0, arr.Length);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
