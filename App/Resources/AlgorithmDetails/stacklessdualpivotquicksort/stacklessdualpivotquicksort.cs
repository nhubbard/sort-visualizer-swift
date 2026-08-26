using System;

public class StacklessDualPivotQuickSort
{
  const int InsertionThreshold = 24;

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

  // Dual-pivot partition of arr[start..end). `scratch` is a fixed index outside this range,
  // borrowed briefly as scratch space by the closing rotation and immediately restored. Returns
  // the boundary between the low region and everything at or above the smaller of the two
  // pivots.
  static int Partition(int[] arr, int start, int end, int scratch)
  {
    int m1 = (start + start + end) / 3;
    int m2 = (start + end + end) / 3;

    if (arr[m1] > arr[m2])
    {
      (arr[m1], arr[start]) = (arr[start], arr[m1]);
      end--;
      (arr[m2], arr[end]) = (arr[end], arr[m2]);
    }
    else
    {
      (arr[m2], arr[start]) = (arr[start], arr[m2]);
      end--;
      (arr[m1], arr[end]) = (arr[end], arr[m1]);
    }

    int low = start;
    int high = end;
    // Reversed from the usual low/high naming: after the swaps above, `start` holds the larger
    // of the two chosen medians and `end` the smaller. Neither position moves again until the
    // closing rotation below, so their values are safe to hold onto directly.
    int pivotMax = arr[start];
    int pivotMin = arr[end];

    int k = low + 1;
    while (k < high)
    {
      if (arr[k] < pivotMin)
      {
        low++;
        (arr[k], arr[low]) = (arr[low], arr[k]);
      }
      else if (arr[k] >= pivotMax)
      {
        do
        {
          high--;
        } while (high > k && arr[high] >= pivotMax);
        (arr[k], arr[high]) = (arr[high], arr[k]);
        if (arr[k] < pivotMin)
        {
          low++;
          (arr[k], arr[low]) = (arr[low], arr[k]);
        }
      }
      k++;
    }

    (arr[start], arr[low]) = (arr[low], arr[start]);
    // Three-way rotation: the value at `end` moves to `scratch`, whatever was borrowed from
    // `scratch` moves to `high`, and whatever was at `high` moves to `end`.
    int displaced = arr[end];
    arr[end] = arr[high];
    arr[high] = arr[scratch];
    arr[scratch] = displaced;

    return low;
  }

  // Sorts arr[start..end) in place with no recursion: a single loop processes one segment at a
  // time, shrinking and partitioning it down to InsertionThreshold elements, finishing with
  // BinaryInsertionSort, then advancing past it to the next segment.
  static void QuickSort(int[] arr, int start, int end)
  {
    // Move every copy of this range's maximum value to the very end first. Those elements are
    // already correctly placed relative to everything else, so the rest of the algorithm never
    // has to look at them again -- and the boundary in front of them becomes fixed scratch
    // space Partition can borrow from.
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
    // should refresh one of its two candidates, since reusing them would just compare equal
    // again.
    bool reuseMedianCandidates = true;

    while (true)
    {
      while (segmentEnd - a > InsertionThreshold)
      {
        if (!reuseMedianCandidates)
        {
          int m = (a + a + segmentEnd) / 3;
          (arr[a], arr[m]) = (arr[m], arr[a]);
        }
        segmentEnd = Partition(arr, a, segmentEnd, tail);
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

      reuseMedianCandidates = true;
      while (a < segmentEnd && arr[a - 1] == arr[a])
      {
        reuseMedianCandidates = false;
        a++;
      }
      if (a == segmentEnd) reuseMedianCandidates = true;
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