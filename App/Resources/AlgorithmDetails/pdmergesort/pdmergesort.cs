using System;
using System.Collections.Generic;

public class PDMergeSort
{
  public static void ReverseRun(int[] arr, int lo, int hi)
  {
    while (lo < hi)
    {
      (arr[lo], arr[hi]) = (arr[hi], arr[lo]);
      lo++;
      hi--;
    }
  }

  // Finds the maximal run starting at indexIn (every adjacent step in the
  // same direction), reversing it in place if that direction was descending.
  // Returns the index where the next run starts, or -1 if this was the last
  // run.
  public static int IdentifyRun(int[] arr, int indexIn, int n)
  {
    if (indexIn >= n - 1)
    {
      return -1;
    }
    int startIndex = indexIn;
    int index = indexIn;
    bool ascending = arr[index] <= arr[index + 1];
    index++;
    while (index < n - 1)
    {
      bool stepAscending = arr[index] <= arr[index + 1];
      if (stepAscending != ascending)
      {
        break;
      }
      index++;
    }
    if (!ascending)
    {
      ReverseRun(arr, startIndex, index);
    }
    return index >= n - 1 ? -1 : index + 1;
  }

  // Merges arr[start..mid) with arr[mid..end) by copying the left run into a
  // scratch buffer and merging forward from the low end.
  public static void MergeUp(int[] arr, int start, int mid, int end, int[] buffer)
  {
    for (int i = 0; i < mid - start; i++)
    {
      buffer[i] = arr[start + i];
    }
    int bufferPointer = 0;
    int left = start;
    int right = mid;
    while (left < right && right < end)
    {
      if (buffer[bufferPointer] <= arr[right])
      {
        arr[left] = buffer[bufferPointer];
        bufferPointer++;
      }
      else
      {
        arr[left] = arr[right];
        right++;
      }
      left++;
    }
    while (left < right)
    {
      arr[left] = buffer[bufferPointer];
      bufferPointer++;
      left++;
    }
  }

  // Merges arr[start..mid) with arr[mid..end) by copying the right run into a
  // scratch buffer and merging backward from the high end.
  public static void MergeDown(int[] arr, int start, int mid, int end, int[] buffer)
  {
    for (int i = 0; i < end - mid; i++)
    {
      buffer[i] = arr[mid + i];
    }
    int bufferPointer = end - mid - 1;
    int left = mid - 1;
    int right = end - 1;
    while (right > left && left >= start)
    {
      if (buffer[bufferPointer] >= arr[left])
      {
        arr[right] = buffer[bufferPointer];
        bufferPointer--;
      }
      else
      {
        arr[right] = arr[left];
        left--;
      }
      right--;
    }
    while (right > left)
    {
      arr[right] = buffer[bufferPointer];
      bufferPointer--;
      right--;
    }
  }

  // Picks whichever of MergeUp/MergeDown needs the smaller scratch copy.
  public static void MergeRuns(int[] arr, int leftStart, int rightStart, int end, int[] buffer)
  {
    if (end - rightStart < rightStart - leftStart)
    {
      MergeDown(arr, leftStart, rightStart, end, buffer);
    }
    else
    {
      MergeUp(arr, leftStart, rightStart, end, buffer);
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n < 2)
    {
      return;
    }

    var runs = new List<int>();
    int lastRun = 0;
    while (lastRun != -1)
    {
      runs.Add(lastRun);
      lastRun = IdentifyRun(arr, lastRun, n);
    }

    int[] buffer = new int[n];
    int runCount = runs.Count;
    while (runCount > 1)
    {
      int i = 0;
      while (i < runCount - 1)
      {
        int end = i + 2 >= runCount ? n : runs[i + 2];
        MergeRuns(arr, runs[i], runs[i + 1], end, buffer);
        i += 2;
      }

      var compacted = new List<int>();
      for (int j = 0; j < runCount; j += 2)
      {
        compacted.Add(runs[j]);
      }
      runs = compacted;
      runCount = runs.Count;
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