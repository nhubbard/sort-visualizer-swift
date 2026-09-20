using System;

public class RemiSort
{
  public static void Sort(int[] a)
  {
    int n = a.Length;
    if (n < 2) return;
    int low = 0, high = Math.Min(n, 1291);
    while (low < high)
    {
      int mid = (low + high) / 2;
      if (mid * mid * mid >= n) high = mid; else low = mid + 1;
    }
    int block = low, runLength = block * block, runs = (n - 1) / runLength + 1;
    int[] keys = new int[runs < 2 ? n : runLength];
    for (int i = 0; i < keys.Length; i++) keys[i] = i;
    bool Greater(int x, int y, int start) =>
      a[start + x] > a[start + y] || (a[start + x] == a[start + y] && x > y);
    void TableSift(int root, int length, int start, int item)
    {
      int j = root;
      while (2 * j + 1 < length)
      {
        j = 2 * j + 1;
        if (j + 1 < length && Greater(keys[j + 1], keys[j], start)) j++;
      }
      while (j > root && Greater(item, keys[j], start)) j = (j - 1) / 2;
      while (j > root)
      {
        int old = keys[j]; keys[j] = item; item = old; j = (j - 1) / 2;
      }
      keys[root] = item;
    }
    void TableSort(int start, int end)
    {
      int length = end - start;
      if (length < 2) return;
      for (int i = (length - 1) / 2; i >= 0; i--) TableSift(i, length, start, keys[i]);
      for (int i = length - 1; i > 0; i--)
      {
        int item = keys[i]; keys[i] = keys[0]; TableSift(0, i, start, item);
      }
      for (int i = 0; i < length; i++)
      {
        if (keys[i] == i) continue;
        int held = a[start + i], j = i, next = keys[i];
        do
        {
          a[start + j] = a[start + next]; keys[j] = j; j = next; next = keys[next];
        } while (next != i);
        a[start + j] = held; keys[j] = j;
      }
    }
    if (runs < 2) { TableSort(0, n); return; }
    int[] buffer = new int[runLength], heap = new int[runs], position = new int[runs], destination = new int[runs];
    for (int run = 0; run < runs; run++)
    {
      int start = run * runLength;
      TableSort(start, Math.Min(start + runLength, n));
      heap[run] = run; position[run] = destination[run] = start;
    }
    bool Less(int x, int y) => a[position[x]] < a[position[y]] || (a[position[x]] == a[position[y]] && x < y);
    void Sift(int item, int start, int size)
    {
      int root = start;
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
    for (int i = (runs - 1) / 2; i >= 0; i--) Sift(heap[i], i, runs);
    int size = runs;
    void Advance(int run)
    {
      position[run]++;
      if (position[run] == Math.Min((run + 1) * runLength, n))
      { size--; Sift(heap[size], 0, size); }
      else Sift(heap[0], 0, size);
    }
    for (int i = 0; i < runLength; i++)
    {
      int run = heap[0]; buffer[i] = a[position[run]]; Advance(run);
    }
    int t = 0, count = 0, cursor = 0;
    while (position[cursor] - destination[cursor] < block) cursor++;
    do
    {
      int run = heap[0]; a[destination[cursor]++] = a[position[run]]; Advance(run); count++;
      if (count == block)
      {
        keys[t++] = cursor > 0 ? destination[cursor] / block - block - 1 : -1;
        cursor = 0; count = 0;
        while (position[cursor] - destination[cursor] < block) cursor++;
      }
    } while (size > 0);
    int end = n;
    while (count > 0) { count--; destination[cursor]--; a[--end] = a[destination[cursor]]; }
    position[runs - 1] = end; keys[keys.Length - 1] = -1; t = 0;
    while (keys[t] != -1) t++;
    int source = 0;
    for (int run = 1; run < runs && source < destination[0]; run++)
    {
      while (destination[run] < position[run])
      {
        keys[t++] = destination[run] / block - block;
        while (keys[t] != -1) t++;
        for (int x = 0; x < block; x++) a[destination[run] + x] = a[source + x];
        destination[run] += block; source += block;
      }
    }
    Array.Copy(buffer, 0, a, 0, runLength);
    int blocks = (end - runLength) / block;
    for (int i = 0; i < blocks; i++)
    {
      if (keys[i] == i) continue;
      Array.Copy(a, runLength + i * block, buffer, 0, block);
      int j = i, next = keys[i];
      do
      {
        Array.Copy(a, runLength + next * block, a, runLength + j * block, block);
        keys[j] = j; j = next; next = keys[next];
      } while (next != i);
      Array.Copy(buffer, 0, a, runLength + j * block, block); keys[j] = j;
    }
  }
  public static void Main()
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    Console.WriteLine("[" + string.Join(", ", array) + "]");
  }
}