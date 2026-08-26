using System;
using System.Collections.Generic;

public class DropMergeSort
{
  const int Recency = 8;
  const int EarlyOutTestAt = 4;
  const double EarlyOutDisorderFraction = 0.6;

  // A plain general-purpose sort for arr[lo..hi), used both as the early-out fallback and to
  // sort the leftover "dropped" elements before the final merge. Any decent O(n log n) sort
  // works here -- the algorithm doesn't depend on which one.
  static void QuickSort(int[] arr, int lo, int hi)
  {
    if (hi - lo <= 1) return;
    int pivot = arr[lo + (hi - lo) / 2];
    var less = new List<int>();
    var equal = new List<int>();
    var greater = new List<int>();

    for (int i = lo; i < hi; i++)
    {
      if (arr[i] < pivot)
      {
        less.Add(arr[i]);
      }
      else if (arr[i] > pivot)
      {
        greater.Add(arr[i]);
      }
      else
      {
        equal.Add(arr[i]);
      }
    }

    var lessArr = less.ToArray();
    var greaterArr = greater.ToArray();
    QuickSort(lessArr, 0, lessArr.Length);
    QuickSort(greaterArr, 0, greaterArr.Length);

    int k = lo;
    foreach (int value in lessArr) arr[k++] = value;
    foreach (int value in equal) arr[k++] = value;
    foreach (int value in greaterArr) arr[k++] = value;
  }

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
        QuickSort(arr, 0, length);
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

        int maxOfDropped = arr[read];
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

    QuickSort(arr, write, length);

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