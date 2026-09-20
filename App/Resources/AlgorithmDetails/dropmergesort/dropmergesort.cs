using System;
using System.Collections.Generic;

public class DropMergeSort
{
  const int Recency = 8;
  const int EarlyOutTestAt = 4;
  const double EarlyOutDisorderFraction = 0.6;

  // Branched PDQ fallback, matching the app PDQSortingTemplate.
  private const int InsertSortThreshold = 24;
  private const int NintherThreshold = 128;
  private const int PartialInsertSortLimit = 8;

  private static int PdqLog(int n)
  {
    int log = 0;
    while ((n >>= 1) != 0) log++;
    return log;
  }

  private static void InsertSort(int[] arr, int begin, int end)
  {
    for (int cur = begin + 1; cur < end; cur++)
    {
      if (arr[cur] < arr[cur - 1])
      {
        int tmp = arr[cur];
        int sift = cur;
        int siftMinusOne = cur - 1;
        do
        {
          arr[sift--] = arr[siftMinusOne--];
        } while (sift != begin && tmp < arr[siftMinusOne]);
        arr[sift] = tmp;
      }
    }
  }

  private static void UnguardInsertSort(int[] arr, int begin, int end)
  {
    for (int cur = begin + 1; cur < end; cur++)
    {
      if (arr[cur] < arr[cur - 1])
      {
        int tmp = arr[cur];
        int sift = cur;
        int siftMinusOne = cur - 1;
        do
        {
          arr[sift--] = arr[siftMinusOne--];
        } while (tmp < arr[siftMinusOne]);
        arr[sift] = tmp;
      }
    }
  }

  private static bool PartialInsertSort(int[] arr, int begin, int end)
  {
    int limit = 0;
    for (int cur = begin + 1; cur < end; cur++)
    {
      if (limit > PartialInsertSortLimit) return false;
      if (arr[cur] < arr[cur - 1])
      {
        int tmp = arr[cur];
        int sift = cur;
        int siftMinusOne = cur - 1;
        do
        {
          arr[sift--] = arr[siftMinusOne--];
        } while (sift != begin && tmp < arr[siftMinusOne]);
        arr[sift] = tmp;
        limit += cur - sift;
      }
    }
    return true;
  }

  private static void SortTwo(int[] arr, int a, int b)
  {
    if (arr[b] < arr[a]) (arr[a], arr[b]) = (arr[b], arr[a]);
  }

  private static void SortThree(int[] arr, int a, int b, int c)
  {
    SortTwo(arr, a, b);
    SortTwo(arr, b, c);
    SortTwo(arr, a, b);
  }

  private static (int pivotPos, bool alreadyParted) PartRight(int[] arr, int begin, int end)
  {
    int pivot = arr[begin];
    int first = begin;
    int last = end;

    first++;
    while (arr[first] < pivot) first++;

    if (first - 1 == begin)
    {
      last--;
      while (first < last && !(arr[last] < pivot)) last--;
    }
    else
    {
      last--;
      while (!(arr[last] < pivot)) last--;
    }

    bool alreadyParted = first >= last;
    while (first < last)
    {
      (arr[first], arr[last]) = (arr[last], arr[first]);
      first++;
      while (arr[first] < pivot) first++;
      last--;
      while (!(arr[last] < pivot)) last--;
    }

    int pivotPos = first - 1;
    arr[begin] = arr[pivotPos];
    arr[pivotPos] = pivot;

    return (pivotPos, alreadyParted);
  }

  private static int PartLeft(int[] arr, int begin, int end)
  {
    int pivot = arr[begin];
    int first = begin;
    int last = end;

    last--;
    while (pivot < arr[last]) last--;

    if (last + 1 == end)
    {
      first++;
      while (first < last && !(pivot < arr[first])) first++;
    }
    else
    {
      first++;
      while (!(pivot < arr[first])) first++;
    }

    while (first < last)
    {
      (arr[first], arr[last]) = (arr[last], arr[first]);
      last--;
      while (pivot < arr[last]) last--;
      first++;
      while (!(pivot < arr[first])) first++;
    }

    int pivotPos = last;
    arr[begin] = arr[pivotPos];
    arr[pivotPos] = pivot;
    return pivotPos;
  }

  private static void SiftDown(int[] arr, int begin, int root, int size)
  {
    while (true)
    {
      int child = 2 * root + 1;
      if (child >= size) break;
      if (child + 1 < size && arr[begin + child] < arr[begin + child + 1]) child++;
      if (arr[begin + root] < arr[begin + child])
      {
        (arr[begin + root], arr[begin + child]) = (arr[begin + child], arr[begin + root]);
        root = child;
      }
      else
      {
        break;
      }
    }
  }

  private static void HeapSort(int[] arr, int begin, int end)
  {
    int n = end - begin;
    for (int i = n / 2 - 1; i >= 0; i--) SiftDown(arr, begin, i, n);
    for (int i = n - 1; i > 0; i--)
    {
      (arr[begin], arr[begin + i]) = (arr[begin + i], arr[begin]);
      SiftDown(arr, begin, 0, i);
    }
  }

  private static void PdqLoop(int[] arr, int begin, int end, int badAllowed)
  {
    bool leftmost = true;
    while (true)
    {
      int size = end - begin;

      if (size < InsertSortThreshold)
      {
        if (leftmost) InsertSort(arr, begin, end);
        else UnguardInsertSort(arr, begin, end);
        return;
      }

      int halfSize = size / 2;
      if (size > NintherThreshold)
      {
        SortThree(arr, begin, begin + halfSize, end - 1);
        SortThree(arr, begin + 1, begin + halfSize - 1, end - 2);
        SortThree(arr, begin + 2, begin + halfSize + 1, end - 3);
        SortThree(arr, begin + halfSize - 1, begin + halfSize, begin + halfSize + 1);
        (arr[begin], arr[begin + halfSize]) = (arr[begin + halfSize], arr[begin]);
      }
      else
      {
        SortThree(arr, begin + halfSize, begin, end - 1);
      }

      if (!leftmost && !(arr[begin - 1] < arr[begin]))
      {
        begin = PartLeft(arr, begin, end) + 1;
        continue;
      }

      (int pivotPos, bool alreadyParted) = PartRight(arr, begin, end);

      int leftSize = pivotPos - begin;
      int rightSize = end - (pivotPos + 1);
      bool highUnbalance = leftSize < size / 8 || rightSize < size / 8;

      if (highUnbalance)
      {
        if (--badAllowed == 0)
        {
          HeapSort(arr, begin, end);
          return;
        }

        if (leftSize >= InsertSortThreshold)
        {
          (arr[begin], arr[begin + leftSize / 4]) = (arr[begin + leftSize / 4], arr[begin]);
          (arr[pivotPos - 1], arr[pivotPos - leftSize / 4]) = (arr[pivotPos - leftSize / 4], arr[pivotPos - 1]);
          if (leftSize > NintherThreshold)
          {
            (arr[begin + 1], arr[begin + (leftSize / 4 + 1)]) = (arr[begin + (leftSize / 4 + 1)], arr[begin + 1]);
            (arr[begin + 2], arr[begin + (leftSize / 4 + 2)]) = (arr[begin + (leftSize / 4 + 2)], arr[begin + 2]);
            (arr[pivotPos - 2], arr[pivotPos - (leftSize / 4 + 1)]) = (arr[pivotPos - (leftSize / 4 + 1)], arr[pivotPos - 2]);
            (arr[pivotPos - 3], arr[pivotPos - (leftSize / 4 + 2)]) = (arr[pivotPos - (leftSize / 4 + 2)], arr[pivotPos - 3]);
          }
        }

        if (rightSize >= InsertSortThreshold)
        {
          (arr[pivotPos + 1], arr[pivotPos + (1 + rightSize / 4)]) = (arr[pivotPos + (1 + rightSize / 4)], arr[pivotPos + 1]);
          (arr[end - 1], arr[end - rightSize / 4]) = (arr[end - rightSize / 4], arr[end - 1]);
          if (rightSize > NintherThreshold)
          {
            (arr[pivotPos + 2], arr[pivotPos + (2 + rightSize / 4)]) = (arr[pivotPos + (2 + rightSize / 4)], arr[pivotPos + 2]);
            (arr[pivotPos + 3], arr[pivotPos + (3 + rightSize / 4)]) = (arr[pivotPos + (3 + rightSize / 4)], arr[pivotPos + 3]);
            (arr[end - 2], arr[end - (1 + rightSize / 4)]) = (arr[end - (1 + rightSize / 4)], arr[end - 2]);
            (arr[end - 3], arr[end - (2 + rightSize / 4)]) = (arr[end - (2 + rightSize / 4)], arr[end - 3]);
          }
        }
      }
      else
      {
        if (alreadyParted && PartialInsertSort(arr, begin, pivotPos) && PartialInsertSort(arr, pivotPos + 1, end))
        {
          return;
        }
      }

      PdqLoop(arr, begin, pivotPos, badAllowed);
      begin = pivotPos + 1;
      leftmost = false;
    }
  }

  static void PdqSort(int[] arr, int begin, int end) { if (end - begin > 1) PdqLoop(arr, begin, end, PdqLog(end - begin)); }



  public static void Sort(int[] arr)
  {
    int length = arr.Length;
    if (length < 2) return;

    var dropped = new List<int>();
    int numDroppedInARow = 0;
    int read = 0;
    int write = 0;
    int iteration = 0;
    int earlyOutStop = length / EarlyOutTestAt;

    while (read < length)
    {
      iteration++;
      if (iteration == earlyOutStop && dropped.Count > read * EarlyOutDisorderFraction)
      {
        // Too disordered for the adaptive approach to be worth it: flush what's been dropped so
        // far back into the array and fall back to a plain full sort.
        foreach (int value in dropped)
        {
          arr[write] = value;
          write++;
        }
        dropped.Clear();
        PdqSort(arr, 0, length);
        return;
      }

      if (write == 0 || arr[read] >= arr[write - 1])
      {
        // In order -- keep it.
        arr[write] = arr[read];
        write++;
        read++;
        numDroppedInARow = 0;
      }
      else if (numDroppedInARow == 0 && write >= 2 && arr[read] >= arr[write - 2])
      {
        // Quick undo: the element two back would have accepted this one just fine, so drop the
        // one right before it instead of the new element.
        dropped.Add(arr[write - 1]);
        arr[write - 1] = arr[read];
        read++;
      }
      else if (numDroppedInARow < Recency)
      {
        dropped.Add(arr[read]);
        read++;
        numDroppedInARow++;
      }
      else
      {
        // Accepting something `numDroppedInARow` elements back made every subsequent element
        // drop -- that accept was a mistake. Undo it, and any other recently accepted elements
        // bigger than the dropped run's maximum.
        dropped.RemoveRange(dropped.Count - numDroppedInARow, numDroppedInARow);
        read -= numDroppedInARow;

        int numBacktracked = 1;
        write--;

        int maxOfDropped = read;
        for (int scan = read + 1; scan <= read + numDroppedInARow; scan++)
        {
          if (arr[scan] > maxOfDropped) maxOfDropped = arr[scan];
        }

        while (write >= 1 && maxOfDropped < arr[write - 1])
        {
          write--;
          numBacktracked++;
        }

        for (int scan = write; scan < write + numBacktracked; scan++)
        {
          dropped.Add(arr[scan]);
        }

        numDroppedInARow = 0;
      }
    }

    for (int offset = 0; offset < dropped.Count; offset++)
    {
      arr[write + offset] = dropped[offset];
    }

    PdqSort(arr, write, length);

    // Copy the now-sorted dropped tail before the final backward merge starts overwriting
    // arr[write..] in place.
    var buffer = new int[dropped.Count];
    Array.Copy(arr, write, buffer, 0, dropped.Count);

    int i = buffer.Length - 1;
    int j = write - 1;
    int k = length - 1;

    while (i >= 0)
    {
      if (j < 0 || buffer[i] > arr[j])
      {
        arr[k] = buffer[i];
        k--;
        i--;
      }
      else
      {
        arr[k] = arr[j];
        k--;
        j--;
      }
    }
  }

  public static void Main(String[] args)
  {
    int[] array = {
      0, 1, 2, 3, 4, 9, 6, 7, 8, 5, 10, 11, 12, 13, 14,
      15, 21, 17, 18, 19, 20, 16, 22, 23, 24, 28, 26, 27, 25, 29
    };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}