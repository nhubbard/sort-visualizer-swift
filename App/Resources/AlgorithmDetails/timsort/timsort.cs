using System;
using System.Collections.Generic;

public class TimSort
{
  private struct Run
  {
    public int Base;
    public int Length;

    public Run(int baseIndex, int length)
    {
      Base = baseIndex;
      Length = length;
    }
  }

  private static int MinRunLength(int value)
  {
    int n = value;
    int remainder = 0;
    while (n >= 32)
    {
      remainder |= n & 1;
      n >>= 1;
    }
    return n + remainder;
  }

  private static int CountRun(int[] values, int start)
  {
    int end = start + 1;
    if (end == values.Length) return 1;
    bool descending = values[end] < values[start];
    end++;
    if (descending)
    {
      while (end < values.Length && values[end] < values[end - 1]) end++;
      for (int left = start, right = end - 1; left < right; left++, right--)
      {
        (values[left], values[right]) = (values[right], values[left]);
      }
    }
    else
    {
      while (end < values.Length && values[end] >= values[end - 1]) end++;
    }
    return end - start;
  }

  private static void BinaryInsertion(int[] values, int start, int end, int sortedEnd)
  {
    for (int index = sortedEnd; index < end; index++)
    {
      int pivot = values[index];
      int low = start;
      int high = index;
      while (low < high)
      {
        int middle = low + (high - low) / 2;
        if (values[middle] <= pivot) low = middle + 1;
        else high = middle;
      }
      for (int shift = index; shift > low; shift--) values[shift] = values[shift - 1];
      values[low] = pivot;
    }
  }

  private static void Merge(int[] values, List<Run> runs, int index)
  {
    Run first = runs[index];
    Run second = runs[index + 1];
    int[] left = values[first.Base..second.Base];
    int[] right = values[second.Base..(second.Base + second.Length)];
    int i = 0;
    int j = 0;
    int destination = first.Base;
    while (i < left.Length && j < right.Length)
    {
      if (left[i] <= right[j]) values[destination++] = left[i++];
      else values[destination++] = right[j++];
    }
    while (i < left.Length) values[destination++] = left[i++];
    while (j < right.Length) values[destination++] = right[j++];
    runs[index] = new Run(first.Base, first.Length + second.Length);
    runs.RemoveAt(index + 1);
  }

  public static void Sort(int[] values)
  {
    int n = values.Length;
    if (n < 2) return;
    int minimum = MinRunLength(n);
    List<Run> runs = new();
    int cursor = 0;
    while (cursor < n)
    {
      int length = CountRun(values, cursor);
      int forced = Math.Min(minimum, n - cursor);
      if (length < forced)
      {
        BinaryInsertion(values, cursor, cursor + forced, cursor + length);
        length = forced;
      }
      runs.Add(new Run(cursor, length));
      while (runs.Count > 1)
      {
        int index = runs.Count - 2;
        if ((index >= 1 && runs[index - 1].Length <= runs[index].Length + runs[index + 1].Length) ||
            (index >= 2 && runs[index - 2].Length <= runs[index].Length + runs[index - 1].Length))
        {
          if (runs[index - 1].Length < runs[index + 1].Length) index--;
        }
        else if (runs[index].Length > runs[index + 1].Length) break;
        Merge(values, runs, index);
      }
      cursor += length;
    }
    while (runs.Count > 1)
    {
      int index = runs.Count - 2;
      if (index > 0 && runs[index - 1].Length < runs[index + 1].Length) index--;
      Merge(values, runs, index);
    }
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    Console.WriteLine("[" + String.Join(", ", array) + "]");
  }
}
