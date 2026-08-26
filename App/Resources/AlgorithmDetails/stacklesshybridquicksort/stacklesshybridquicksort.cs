using System;

public class StacklessHybridQuickSort
{
  const int InsertionThreshold = 16;

  // Arranges arr[start], arr[mid], arr[end - 1] so the median of the three ends up at `start`,
  // ready to serve as Partition's pivot.
  static void MedianOfThree(int[] arr, int start, int end)
  {
    int mid = start + (end - 1 - start) / 2;
    if (arr[start] > arr[mid])
    {
      (arr[start], arr[mid]) = (arr[mid], arr[start]);
    }
    if (arr[mid] > arr[end - 1])
    {
      (arr[mid], arr[end - 1]) = (arr[end - 1], arr[mid]);
      if (arr[start] > arr[mid]) return;
    }
    (arr[start], arr[mid]) = (arr[mid], arr[start]);
  }

  // Classic two-pointer Hoare partition against the pivot MedianOfThree just placed at `start`.
  // Returns the pivot's final resting index.
  static int Partition(int[] arr, int start, int end)
  {
    MedianOfThree(arr, start, end);
    int pivot = arr[start];
    int i = start, j = end;

    while (true)
    {
      i++;
      while (i < j && arr[i] < pivot) i++;
      j--;
      while (j >= i && arr[j] >= pivot) j--;
      if (i < j)
      {
        (arr[i], arr[j]) = (arr[j], arr[i]);
      }
      else
      {
        (arr[start], arr[j]) = (arr[j], arr[start]);
        return j;
      }
    }
  }

  // Finds where the value at targetIndex belongs among arr[start..end), ties resolving toward
  // the front (a plain lower-bound binary search).
  static int LowerBoundIndex(int[] arr, int start, int end, int targetIndex)
  {
    int lo = start, hi = end;
    while (lo < hi)
    {
      int mid = lo + (hi - lo) / 2;
      if (arr[targetIndex] <= arr[mid])
      {
        hi = mid;
      }
      else
      {
        lo = mid + 1;
      }
    }
    return lo;
  }

  // Sorts arr[start..end) in place using a plain binary-search insertion sort -- the base case
  // once a segment shrinks small enough that further partitioning isn't worth it.
  static void BinaryInsertionSort(int[] arr, int start, int end)
  {
    for (int i = start; i < end; i++)
    {
      int value = arr[i];
      int lo = start, hi = i;
      while (lo < hi)
      {
        int mid = lo + (hi - lo) / 2;
        if (value < arr[mid])
        {
          hi = mid;
        }
        else
        {
          lo = mid + 1;
        }
      }
      int j = i - 1;
      while (j >= lo)
      {
        arr[j + 1] = arr[j];
        j--;
      }
      arr[lo] = value;
    }
  }

  // Sorts arr[start..end) in place with no recursion: a single loop processes one segment at a
  // time, shrinking and partitioning it down to InsertionThreshold elements, finishing with
  // BinaryInsertionSort, then advancing past it to the next segment.
  static void QuickSort(int[] arr, int start, int end)
  {
    // Move every copy of this range's maximum value to the very end first. Those elements are
    // already correctly placed relative to everything else, so the rest of the algorithm never
    // has to look at them again -- and the boundary in front of them becomes the fixed resting
    // place Partition sends each finished pivot out to.
    int maxValue = arr[start];
    for (int i = start + 1; i < end; i++)
    {
      if (arr[i] > maxValue) maxValue = arr[i];
    }

    int tail = end;
    for (int i = end - 1; i >= start; i--)
    {
      if (arr[i] == maxValue)
      {
        tail--;
        (arr[i], arr[tail]) = (arr[tail], arr[i]);
      }
    }

    int a = start;
    int segmentEnd = tail;
    // False right after skipping a run of duplicates below means the next median-of-three
    // should refresh its candidates, since reusing them would just compare equal again.
    bool refreshMedian = true;

    while (true)
    {
      while (segmentEnd - a > InsertionThreshold)
      {
        if (refreshMedian)
        {
          MedianOfThree(arr, a, segmentEnd);
        }
        int pivotIndex = Partition(arr, a, segmentEnd);
        (arr[pivotIndex], arr[tail]) = (arr[tail], arr[pivotIndex]);
        segmentEnd = pivotIndex;
      }

      BinaryInsertionSort(arr, a, segmentEnd);

      a = segmentEnd + 1;
      if (a >= tail)
      {
        if (a - 1 < tail)
        {
          (arr[a - 1], arr[tail]) = (arr[tail], arr[a - 1]);
        }
        return;
      }

      segmentEnd = LowerBoundIndex(arr, a, tail, a - 1);
      (arr[a - 1], arr[tail]) = (arr[tail], arr[a - 1]);

      refreshMedian = true;
      while (a < segmentEnd && arr[a - 1] == arr[a])
      {
        refreshMedian = false;
        a++;
      }
      if (a == segmentEnd) refreshMedian = true;
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n < 2) return;
    QuickSort(arr, 0, n);
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