using System;

public class QuadSort
{
  const int InsertionRun = 4;

  static void InsertionSortRange(int[] arr, int lo, int hi)
  {
    for (int i = lo + 1; i < hi; i++)
    {
      int key = arr[i];
      int j = i - 1;
      while (j >= lo && arr[j] > key)
      {
        arr[j + 1] = arr[j];
        j--;
      }
      arr[j + 1] = key;
    }
  }

  // Merges the two equal-length sorted runs source[lo, lo+runLength) and
  // source[lo+runLength, lo+2*runLength) into dest, filling from both ends toward the middle
  // at once instead of scanning front to back alone.
  static void ParityMerge(int[] source, int lo, int runLength, int[] dest)
  {
    int left = lo;
    int right = lo + runLength;
    int leftEnd = lo + runLength - 1;
    int rightEnd = lo + 2 * runLength - 1;
    int front = lo;
    int back = lo + 2 * runLength - 1;

    for (int step = 0; step < runLength; step++)
    {
      if (source[left] <= source[right])
      {
        dest[front] = source[left];
        left++;
      }
      else
      {
        dest[front] = source[right];
        right++;
      }
      front++;

      if (source[leftEnd] > source[rightEnd])
      {
        dest[back] = source[leftEnd];
        leftEnd--;
      }
      else
      {
        dest[back] = source[rightEnd];
        rightEnd--;
      }
      back--;
    }
  }

  static void MergeRange(int[] source, int lo, int mid, int hi, int[] dest)
  {
    int left = lo;
    int right = mid;
    int outIndex = lo;
    while (left < mid && right < hi)
    {
      if (source[left] <= source[right])
      {
        dest[outIndex] = source[left];
        left++;
      }
      else
      {
        dest[outIndex] = source[right];
        right++;
      }
      outIndex++;
    }
    while (left < mid)
    {
      dest[outIndex] = source[left];
      left++;
      outIndex++;
    }
    while (right < hi)
    {
      dest[outIndex] = source[right];
      right++;
      outIndex++;
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n < 2) return;
    int[] buffer = (int[])arr.Clone();

    for (int lo = 0; lo < n; lo += InsertionRun)
    {
      InsertionSortRange(arr, lo, Math.Min(lo + InsertionRun, n));
    }

    for (int runLength = InsertionRun; runLength < n; runLength *= 2)
    {
      for (int lo = 0; lo < n; lo += runLength * 2)
      {
        int mid = Math.Min(lo + runLength, n);
        int hi = Math.Min(lo + runLength * 2, n);
        if (mid - lo == runLength && hi - mid == runLength)
        {
          ParityMerge(arr, lo, runLength, buffer);
        }
        else if (mid < hi)
        {
          MergeRange(arr, lo, mid, hi, buffer);
        }
        else
        {
          for (int i = lo; i < mid; i++)
          {
            buffer[i] = arr[i];
          }
        }
      }
      Array.Copy(buffer, arr, n);
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