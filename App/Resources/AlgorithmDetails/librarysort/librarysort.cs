using System;
using System.Collections.Generic;

public class LibrarySort
{
  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n <= 1)
    {
      return;
    }

    const int Empty = int.MinValue;
    int capacity = 0;
    int[] slots = Array.Empty<int>();
    // Physical `slots` index of each placed element, ascending by both position and value.
    List<int> positions = new List<int>();

    void Rebalance()
    {
      int count = positions.Count;
      int newCapacity = Math.Max(2, count * 2);
      int[] newSlots = new int[newCapacity];
      for (int i = 0; i < newCapacity; i++)
      {
        newSlots[i] = Empty;
      }
      List<int> newPositions = new List<int>();
      for (int i = 0; i < count; i++)
      {
        int pos = positions[i];
        int newPos = i * 2;
        newSlots[newPos] = slots[pos];
        newPositions.Add(newPos);
      }
      slots = newSlots;
      positions = newPositions;
      capacity = newCapacity;
    }

    void Insert(int value)
    {
      if (positions.Count == capacity)
      {
        Rebalance();
      }

      // Upper-bound binary search: first slot whose value is strictly greater than `value`.
      int lo = 0;
      int hi = positions.Count;
      while (lo < hi)
      {
        int mid = (lo + hi) / 2;
        if (slots[positions[mid]] > value)
        {
          hi = mid;
        }
        else
        {
          lo = mid + 1;
        }
      }
      int k = lo;
      int targetPos = k == 0 ? 0 : positions[k - 1] + 1;

      if (!(targetPos == capacity || slots[targetPos] != Empty))
      {
        slots[targetPos] = value;
        positions.Insert(k, targetPos);
        return;
      }

      // Either targetPos is already occupied, or targetPos == capacity (new maximum, no room
      // left of the structure's end). Search BOTH directions for the nearest gap and shift
      // whichever side is closer.
      int leftGap = targetPos - 1;
      while (leftGap >= 0 && slots[leftGap] != Empty)
      {
        leftGap--;
      }
      int rightGap = targetPos;
      while (rightGap < capacity && slots[rightGap] != Empty)
      {
        rightGap++;
      }
      int leftDistance = leftGap >= 0 ? targetPos - leftGap : int.MaxValue;
      int rightDistance = rightGap < capacity ? rightGap - targetPos : int.MaxValue;

      if (rightDistance <= leftDistance)
      {
        int i = rightGap;
        while (i > targetPos)
        {
          slots[i] = slots[i - 1];
          i--;
        }
        for (int idx = k; idx < k + (rightGap - targetPos); idx++)
        {
          positions[idx]++;
        }
        slots[targetPos] = value;
        positions.Insert(k, targetPos);
      }
      else
      {
        int shiftCount = (targetPos - 1) - leftGap;
        int i = leftGap;
        while (i < targetPos - 1)
        {
          slots[i] = slots[i + 1];
          i++;
        }
        for (int idx = k - shiftCount; idx < k; idx++)
        {
          positions[idx]--;
        }
        slots[targetPos - 1] = value;
        positions.Insert(k, targetPos - 1);
      }
    }

    for (int i = 0; i < n; i++)
    {
      Insert(arr[i]);
    }

    for (int i = 0; i < n; i++)
    {
      arr[i] = slots[positions[i]];
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