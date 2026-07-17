using System;

public class WeavedMergeSort
{
  private static void Merge(int[] arr, int[] tmp, int length, int residue, int modulus)
  {
    if (residue + modulus >= length)
    {
      return;
    }
    int low = residue;
    int high = residue + modulus;
    int dmodulus = modulus << 1;

    Merge(arr, tmp, length, low, dmodulus);
    Merge(arr, tmp, length, high, dmodulus);

    int nxt = residue;
    while (low < length && high < length)
    {
      if (arr[low] > arr[high] || (arr[low] == arr[high] && low > high))
      {
        tmp[nxt] = arr[high];
        high += dmodulus;
      }
      else
      {
        tmp[nxt] = arr[low];
        low += dmodulus;
      }
      nxt += modulus;
    }
    if (low >= length)
    {
      while (high < length)
      {
        tmp[nxt] = arr[high];
        nxt += modulus;
        high += dmodulus;
      }
    }
    else
    {
      while (low < length)
      {
        tmp[nxt] = arr[low];
        nxt += modulus;
        low += dmodulus;
      }
    }
    for (int i = residue; i < length; i += modulus)
    {
      arr[i] = tmp[i];
    }
  }

  public static void Sort(int[] arr)
  {
    int[] tmp = new int[arr.Length];
    Merge(arr, tmp, arr.Length, 0, 1);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
