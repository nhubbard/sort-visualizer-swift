using System;

public class FlanSort
{
  const int Gap = 14, Ratio = 4;
  readonly int[] a;
  readonly int[] position = new int[Gap + 2], heap = new int[Gap + 2];
  ulong state = 0x9e3779b97f4a7c15UL;
  public static void Sort(int[] values) { if (values.Length > 1) new FlanSort(values).Execute(); }

  FlanSort(int[] values)
  {
    a = values;
    unchecked
    {
      foreach (int value in a) state = (state ^ (ulong)(long)value) * 0xbf58476d1ce4e5b9UL + 0x94d049bb133111ebUL;
    }
  }
  int Choice(int count)
  {
    unchecked
    {
      state ^= state >> 12; state ^= state << 25; state ^= state >> 27;
      return (int)((state * 0x2545f4914f6cdd1dUL) % (ulong)count);
    }
  }
  void Swap(int i, int j) { int held = a[i]; a[i] = a[j]; a[j] = held; }
  int Median(int i, int m, int j)
  {
    if (a[m] > a[i]) { if (a[m] < a[j]) return m; return a[i] > a[j] ? i : j; }
    if (a[m] > a[j]) return m;
    return a[i] < a[j] ? i : j;
  }
  int Ninther(int first, int last)
  {
    int step = (last - first) / 9;
    return Median(Median(first, first + step, first + 2 * step),
      Median(first + 3 * step, first + 4 * step, first + 5 * step),
      Median(first + 6 * step, first + 7 * step, first + 8 * step));
  }
  int Pivot(int first, int last)
  {
    int step = (last - first) / 3;
    return Median(Ninther(first, first + step), Ninther(first + step, first + 2 * step), Ninther(first + 2 * step, last));
  }
  int BinarySearch(int first, int last, int value, bool backward)
  {
    while (first < last)
    {
      int middle = first + (last - first) / 2;
      bool found = backward ? a[middle] < value : a[middle] > value;
      if (found) last = middle; else first = middle + 1;
    }
    return first;
  }
  void Insert(int value, int from, int to)
  {
    while (from > to) { from--; a[from + 1] = a[from]; }
    a[to] = value;
  }
  void Insertion(int first, int last)
  {
    for (int i = first + 1; i < last; i++)
    {
      int value = a[i]; Insert(value, i, BinarySearch(first, i, value, false));
    }
  }
  int BlockSearch(int first, int last, int value, bool right)
  {
    while (first < last)
    {
      int middle = first + ((last - first) / (Gap + 1) / 2) * (Gap + 1);
      bool found = right ? a[middle] > value : a[middle] >= value;
      if (found) last = middle; else first = middle + Gap + 1;
    }
    return first;
  }
  void Retrieve(int finish, int scratch, int pEnd, int boundary, bool backward)
  {
    int destination = finish - 1, block = pEnd - (Gap + 1);
    while (block > scratch + Gap)
    {
      int item = BinarySearch(block - Gap, block, boundary, backward) - 1;
      block -= Gap + 1;
      while (item >= block) { Swap(destination, item); destination--; item--; }
    }
    int lastItem = BinarySearch(scratch, scratch + Gap, boundary, backward) - 1;
    while (lastItem >= scratch) { Swap(destination, lastItem); destination--; lastItem--; }
  }
  void LibrarySort(int first, int last, int scratch, int boundary, bool backward)
  {
    int length = last - first;
    if (length < 32) { Insertion(first, last); return; }
    int count = length;
    while (count >= 32) count = (count - 1) / Ratio + 1;
    int i = first + count, trigger = first + Ratio * count;
    int pEnd = scratch + (count + 1) * (Gap + 1) + Gap;
    Insertion(first, i);
    for (int k = 0; k < count; k++) Swap(first + k, scratch + k * (Gap + 1) + Gap);
    while (i < last)
    {
      if (i == trigger)
      {
        Retrieve(i, scratch, pEnd, boundary, backward);
        count = i - first;
        pEnd = scratch + (count + 1) * (Gap + 1) + Gap;
        trigger = first + (trigger - first) * Ratio;
        for (int k = 0; k < count; k++) Swap(first + k, scratch + k * (Gap + 1) + Gap);
      }
      int value = a[i];
      int block = BlockSearch(scratch + Gap, pEnd - (Gap + 1), value, false);
      if (a[block] == value)
      {
        int afterEqual = BlockSearch(block + Gap + 1, pEnd - (Gap + 1), value, true);
        block += Choice((afterEqual - block) / (Gap + 1)) * (Gap + 1);
      }
      int loc = BinarySearch(block - Gap, block, boundary, backward);
      if (loc == block)
      {
        do { block += Gap + 1; }
        while (block < pEnd && BinarySearch(block - Gap, block, boundary, backward) == block);
        if (block == pEnd)
        {
          Retrieve(i, scratch, pEnd, boundary, backward);
          count = i - first;
          pEnd = scratch + (count + 1) * (Gap + 1) + Gap;
          trigger = first + (trigger - first) * Ratio;
          for (int k = 0; k < count; k++) Swap(first + k, scratch + k * (Gap + 1) + Gap);
        }
        else
        {
          int firstItem = BinarySearch(block - Gap, block, boundary, backward);
          int distance = block - Math.Max(firstItem, block - Gap / 2);
          int source = block - distance, destination = block;
          while (source > loc - distance) { source--; destination--; Swap(destination, source); }
        }
      }
      else
      {
        int displaced = a[loc]; a[i] = displaced; i++;
        Insert(value, loc, BinarySearch(block - Gap, loc, value, false));
      }
    }
    Retrieve(last, scratch, pEnd, boundary, backward);
  }
  bool Less(int x, int y)
  {
    int left = a[position[x]], right = a[position[y]];
    return left < right || (left == right && x < y);
  }
  void Sift(int item, int first, int size)
  {
    int root = first;
    while (2 * root + 2 < size)
    {
      int left = 2 * root + 1, child = Less(heap[left], heap[left + 1]) ? left : left + 1;
      if (!Less(heap[child], item)) break;
      heap[root] = heap[child]; root = child;
    }
    int last = 2 * root + 1;
    if (last < size && Less(heap[last], item)) { heap[root] = heap[last]; root = last; }
    heap[root] = item;
  }
  void Merge(int runLength, int finish, int destination, int count)
  {
    if (count < 2)
    {
      if (count == 1) while (position[0] < finish) { Swap(destination, position[0]); destination++; position[0]++; }
      return;
    }
    int first = position[0];
    for (int i = 0; i < count; i++) heap[i] = i;
    for (int i = (count - 1) / 2; i >= 0; i--) Sift(heap[i], i, count);
    int size = count;
    while (size > 0)
    {
      int run = heap[0]; Swap(destination, position[run]); destination++; position[run]++;
      if (position[run] == Math.Min(first + (run + 1) * runLength, finish))
      { size--; Sift(heap[size], 0, size); }
      else Sift(heap[0], 0, size);
    }
  }
  void Execute()
  {
    int first = 0, finish = a.Length;
    while (finish - first >= 32)
    {
      int value = a[Pivot(first, finish)];
      int before = first, i = first - 1, j = finish, after = finish;
      while (true)
      {
        i++;
        while (i < j)
        {
          if (a[i] == value) { Swap(before, i); before++; }
          else if (a[i] < value) break;
          i++;
        }
        j--;
        while (j > i)
        {
          if (a[j] == value) { after--; Swap(after, j); }
          else if (a[j] > value) break;
          j--;
        }
        if (i < j) Swap(i, j);
        else
        {
          if (before == finish) return;
          if (j < i) j++;
          while (before > first) { i--; before--; Swap(i, before); }
          while (after < finish) { Swap(j, after); j++; after++; }
          break;
        }
      }
      int left = i - first, right = finish - j, count = 0;
      if (left <= right)
      {
        int move = finish - left; left = Math.Max((right + 1) / (Gap + 1), 16);
        for (int k = first; k < i; k += left)
        { LibrarySort(k, Math.Min(k + left, i), j, value, true); position[count++] = k; }
        Merge(left, i, move, count);
        if (j - i < move - j)
        { while (i < j) { move--; Swap(i, move); i++; } finish = move; }
        else { while (move > j) { move--; Swap(i, move); i++; } finish = i; }
      }
      else
      {
        int move = first + right; right = Math.Max((left + 1) / (Gap + 1), 16);
        for (int k = j; k < finish; k += right)
        { LibrarySort(k, Math.Min(k + right, finish), first, value, false); position[count++] = k; }
        Merge(right, finish, first, count);
        if (i - move < j - i)
        { while (move < i) { j--; Swap(move, j); move++; } first = j; }
        else { while (j > i) { j--; Swap(move, j); move++; } first = move; }
      }
    }
    Insertion(first, finish);
  }

  public static void Main()
  {
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56
    };
    Sort(array);
    Console.WriteLine("[" + string.Join(", ", array) + "]");
  }
}
