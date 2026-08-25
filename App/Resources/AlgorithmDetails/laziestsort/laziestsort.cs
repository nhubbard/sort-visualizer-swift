using System;

public class LaziestSort
{
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

  static void SwapRange(int[] arr, int a, int b, int length)
  {
    for (int i = 0; i < length; i++)
    {
      (arr[a + i], arr[b + i]) = (arr[b + i], arr[a + i]);
    }
  }

  // Swaps the two adjacent blocks arr[lo, mid) and arr[mid, hi) so their order is
  // reversed, using no auxiliary storage: the smaller of the two remaining pieces is
  // always swapped whole against an equal-sized piece of the other, which shrinks one
  // piece to nothing a little at a time until both are exhausted.
  static void Rotate(int[] arr, int lo, int mid, int hi)
  {
    int i = mid - lo;
    int j = hi - mid;
    if (i == 0 || j == 0)
    {
      return;
    }
    while (i != j)
    {
      if (i < j)
      {
        SwapRange(arr, mid - i, mid + j - i, i);
        j -= i;
      }
      else
      {
        SwapRange(arr, mid - i, mid, j);
        i -= j;
      }
    }
    SwapRange(arr, mid - i, mid, i);
  }

  // Finds the first index in [lo, hi) whose element is not less than value, by doubling
  // the step size until it overshoots and then binary-searching the resulting bracket,
  // rather than scanning one element at a time. Assumes arr[lo] < value.
  static int Gallop(int[] arr, int lo, int hi, int value)
  {
    int left = lo;
    int step = 1;
    int right = lo + step;
    while (right < hi && arr[right] < value)
    {
      left = right;
      step *= 2;
      right = lo + step;
    }
    right = Math.Min(right, hi);
    while (right - left > 1)
    {
      int mid = (left + right) / 2;
      if (arr[mid] < value)
      {
        left = mid;
      }
      else
      {
        right = mid;
      }
    }
    return right;
  }

  // Merges the sorted run arr[lo, mid) into the sorted run arr[mid, hi) in place. `left`
  // tracks the first not-yet-placed element of the left run, and `right` tracks the
  // start of the not-yet-consumed remainder of the right run.
  static void Merge(int[] arr, int lo, int mid, int hi)
  {
    int left = lo;
    int right = mid;
    while (left < right && right < hi)
    {
      if (arr[left] <= arr[right])
      {
        left++;
      }
      else
      {
        int boundary = Gallop(arr, right, hi, arr[left]);
        Rotate(arr, left, right, boundary);
        left += boundary - right;
        right = boundary;
      }
    }
  }

  static int IntegerSqrt(int n)
  {
    int r = (int)Math.Sqrt(n);
    while ((long)(r + 1) * (r + 1) <= n)
    {
      r++;
    }
    while ((long)r * r > n)
    {
      r--;
    }
    return r;
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n <= 16)
    {
      BinaryInsertionSort(arr, 0, n);
      return;
    }

    int blockSize = Math.Max(16, IntegerSqrt(n));
    for (int low = 0; low < n; low += blockSize)
    {
      BinaryInsertionSort(arr, low, Math.Min(low + blockSize, n));
    }

    // Merge blocks back to front: the already-sorted run always starts at
    // mergedStart, and each step folds the block immediately before it into that run.
    int numBlocks = (n + blockSize - 1) / blockSize;
    int mergedStart = (numBlocks - 1) * blockSize;
    for (int i = numBlocks - 2; i >= 0; i--)
    {
      int leftStart = i * blockSize;
      Merge(arr, leftStart, mergedStart, n);
      mergedStart = leftStart;
    }
  }

  public static void Main(String[] args)
  {
    int[] array = {
      55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79, 21, 88, 5, 51, 66, 29, 44, 12
    };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}