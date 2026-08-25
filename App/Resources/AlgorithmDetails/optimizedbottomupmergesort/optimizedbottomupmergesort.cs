using System;

public class OptimizedBottomUpMergeSort
{
  const int BlockSize = 16;

  static void BinaryInsertionSort(int[] arr, int lo, int hi)
  {
    for (int i = lo + 1; i < hi; i++)
    {
      int key = arr[i];
      int left = lo;
      int right = i;
      while (left < right)
      {
        int mid = (left + right) / 2;
        if (arr[mid] <= key)
        {
          left = mid + 1;
        }
        else
        {
          right = mid;
        }
      }
      for (int j = i; j > left; j--)
      {
        arr[j] = arr[j - 1];
      }
      arr[left] = key;
    }
  }

  static void Merge(int[] src, int[] dst, int low, int mid, int high)
  {
    int i = low;
    int j = mid;
    int k = low;
    while (i < mid && j < high)
    {
      if (src[i] <= src[j])
      {
        dst[k++] = src[i++];
      }
      else
      {
        dst[k++] = src[j++];
      }
    }
    while (i < mid)
    {
      dst[k++] = src[i++];
    }
    while (j < high)
    {
      dst[k++] = src[j++];
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n < BlockSize)
    {
      BinaryInsertionSort(arr, 0, n);
      return;
    }

    // Pre-pass: sort fixed-size blocks with binary insertion sort so the merge phase can
    // start from already-sorted runs instead of single elements.
    for (int low = 0; low < n; low += BlockSize)
    {
      BinaryInsertionSort(arr, low, Math.Min(low + BlockSize, n));
    }

    // Merge phase: ping-pong between arr and scratch, alternating direction every pass,
    // instead of always merging into scratch and copying the whole buffer back.
    int[] scratch = new int[n];
    int[] src = arr;
    int[] dst = scratch;
    int passes = 0;
    for (int width = BlockSize; width < n; width *= 2)
    {
      for (int low = 0; low < n; low += 2 * width)
      {
        int mid = Math.Min(low + width, n);
        int high = Math.Min(low + 2 * width, n);
        if (mid < high)
        {
          Merge(src, dst, low, mid, high);
        }
        else
        {
          Array.Copy(src, low, dst, low, mid - low);
        }
      }
      int[] t = src;
      src = dst;
      dst = t;
      passes++;
    }

    // An even number of passes lands the sorted result back in arr on its own; an odd
    // number leaves it in scratch, needing this one explicit copy back.
    if (passes % 2 == 1)
    {
      Array.Copy(src, arr, n);
    }
  }

  public static void Main(String[] args)
  {
    int[] array = {
      81, 14, 3, 94, 35, 31, 28, 17, 94, 13, 86, 94, 69, 11, 75, 54,
      4, 3, 11, 27, 29, 64, 77, 3, 71, 25, 91, 83, 89, 69, 53, 28,
      57, 75, 35, 0, 97, 20, 89, 54
    };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}