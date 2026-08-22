using System;

public class MinMaxHeapSort
{
  static int BitLength(int value)
  {
    int length = 0;
    while (value > 0)
    {
      value >>= 1;
      length++;
    }
    return length;
  }

  static bool IsMinLevel(int index)
  {
    return BitLength(index + 1) % 2 == 1;
  }

  static bool BetterThan(int a, int b, bool minLevel)
  {
    return minLevel ? a < b : a > b;
  }

  static void Downheap(int[] arr, int start, int size)
  {
    int i = start;
    while (true)
    {
      bool minLevel = IsMinLevel(i);
      int left = 2 * i + 1;
      int right = 2 * i + 2;
      if (left >= size)
        return;
      int winner = left;
      if (right < size && BetterThan(arr[right], arr[winner], minLevel))
        winner = right;
      int baseIndex = 4 * i + 3;
      for (int offset = 0; offset < 4; offset++)
      {
        int gc = baseIndex + offset;
        if (gc < size && BetterThan(arr[gc], arr[winner], minLevel))
          winner = gc;
      }
      bool isGrandchild = winner >= baseIndex;
      bool extreme = BetterThan(arr[winner], arr[i], minLevel);
      if (!isGrandchild)
      {
        if (extreme)
          (arr[i], arr[winner]) = (arr[winner], arr[i]);
        return;
      }
      if (extreme)
      {
        (arr[i], arr[winner]) = (arr[winner], arr[i]);
      }
      else
      {
        return;
      }
      int parent = (winner - 1) / 2;
      if (minLevel)
      {
        if (arr[winner] > arr[parent])
          (arr[parent], arr[winner]) = (arr[winner], arr[parent]);
      }
      else
      {
        if (arr[winner] < arr[parent])
          (arr[parent], arr[winner]) = (arr[winner], arr[parent]);
      }
      i = winner;
    }
  }

  static void Heapify(int[] arr, int length)
  {
    for (int i = (length - 1) / 2; i >= 0; i--)
    {
      Downheap(arr, i, length);
    }
  }

  static int StoreMax(int[] arr, int heapSize)
  {
    if (heapSize <= 1)
      return heapSize;
    int imax = 1;
    if (heapSize > 2 && arr[2] > arr[1])
      imax = 2;
    int last = heapSize - 1;
    (arr[imax], arr[last]) = (arr[last], arr[imax]);
    int newSize = last;
    if (imax < newSize)
      Downheap(arr, imax, newSize);
    return newSize;
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n <= 1)
      return;
    Heapify(arr, n);
    int heapSize = n;
    for (int i = 0; i < n - 1; i++)
    {
      heapSize = StoreMax(arr, heapSize);
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