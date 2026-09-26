using System;

public static class CircularGrailSort
{
  private static int[] items = Array.Empty<int>();
  private static int count;

  private static void Swap(int a, int b)
  {
    a %= count;
    b %= count;
    (items[a], items[b]) = (items[b], items[a]);
  }

  private static void ShiftForward(int a, int middle, int end)
  {
    while (middle < end) Swap(a++, middle++);
  }

  private static void ShiftBackward(int start, int middle, int end)
  {
    while (middle > start) Swap(--end, --middle);
  }

  private static void Insertion(int start, int end)
  {
    for (int first = start + 1; first < end; first++)
    {
      int i = first;
      while (i > start && items[(i - 1) % count] > items[i % count]) Swap(i, --i);
    }
  }

  private static void MultiSwap(int a, int b, int length)
  {
    for (int i = 0; i < length; i++) Swap(a + i, b + i);
  }

  private static void Rotate(int start, int middle, int end)
  {
    int left = middle - start;
    int right = end - middle;
    while (left > 0 && right > 0)
    {
      if (right < left)
      {
        MultiSwap(middle - right, middle, right);
        end -= right;
        middle -= right;
        left -= right;
      }
      else
      {
        MultiSwap(start, middle, left);
        start += left;
        middle += left;
        right -= left;
      }
    }
  }

  private static void InPlaceMerge(int start, int middle, int end)
  {
    int i = start;
    while (i < middle && middle < end)
    {
      if (items[i % count] > items[middle % count])
      {
        int k = middle + 1;
        while (k < end && items[i % count] > items[k % count]) k++;
        Rotate(i, middle, k);
        i += k - middle;
        middle = k;
      }
      else i++;
    }
  }

  private static int Merge(int p, int start, int middle, int end, bool full)
  {
    int i = start;
    int j = middle;
    while (i < middle && j < end)
    {
      if (items[i % count] <= items[j % count]) Swap(p++, i++);
      else Swap(p++, j++);
    }
    if (i < middle)
    {
      if (i > p) ShiftForward(p, i, middle);
    }
    else if (full) ShiftForward(p, j, end);
    return i < middle ? i : j;
  }

  private static bool BlockLess(int a, int b, int length)
  {
    if (items[a % count] != items[b % count]) return items[a % count] < items[b % count];
    return items[(a + length - 1) % count] < items[(b + length - 1) % count];
  }

  private static void BlockMerge(int start, int middle, int end, int length)
  {
    int b1 = end - (end - middle - 1) % length - 1;
    if (b1 <= middle)
    {
      Merge(start - length, start, middle, end, true);
      return;
    }
    int b2 = b1;
    for (int i = middle - length; i > start && BlockLess(b1, i, length); i -= length) b2 -= length;
    for (int j = start; j < b1 - length; j += length)
    {
      int minimum = j;
      for (int i = j + length; i < b1; i += length)
        if (BlockLess(i, minimum, length)) minimum = i;
      if (minimum != j) MultiSwap(j, minimum, length);
    }
    int frontier = start;
    for (int i = start + length; i < b2; i += length)
    {
      frontier = Merge(frontier - length, frontier, i, i + length, false);
      if (frontier < i)
      {
        ShiftBackward(frontier, i, i + length);
        frontier += length;
      }
    }
    Merge(frontier - length, frontier, b1, end, true);
  }

  public static void Sort(int[] array)
  {
    items = array;
    count = array.Length;
    if (count < 2) return;
    if (count <= 16)
    {
      Insertion(0, count);
      return;
    }
    int block = 1;
    while (block * block < count) block *= 2;
    int i = block;
    int run = 1;
    int rolling = count - block;
    int end = count;
    while (run <= block)
    {
      while (i + 2 * run < end)
      {
        Merge(i - run, i, i + run, i + 2 * run, true);
        i += 2 * run;
      }
      if (i + run < end) Merge(i - run, i, i + run, end, true);
      else ShiftForward(i - run, i, end);
      i = end + block - run;
      end = i + rolling;
      run *= 2;
    }
    while (run < rolling)
    {
      while (i + 2 * run < end)
      {
        BlockMerge(i, i + run, i + 2 * run, block);
        i += 2 * run;
      }
      if (i + run < end) BlockMerge(i, i + run, end, block);
      else ShiftForward(i - block, i, end);
      i = end;
      end += rolling;
      run *= 2;
    }
    Insertion(i - block, i);
    InPlaceMerge(i - block, i, end);
    Rotate(0, (i - block) % count, count);
  }

  public static void Main()
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    Console.WriteLine("[" + string.Join(", ", array) + "]");
  }
}