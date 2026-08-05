using System;

class PoplarHeapSort
{
  static int Hyperfloor(int n)
  {
    int power = 1;
    while (power * 2 <= n)
    {
      power *= 2;
    }
    return power;
  }

  static void UncheckedInsertionSort(int[] array, int first, int last)
  {
    int cur = first + 1;
    while (cur != last)
    {
      if (array[cur] < array[cur - 1])
      {
        int tmp = array[cur];
        int sift = cur;
        int sift1 = cur - 1;
        while (true)
        {
          array[sift] = array[sift1];
          sift--;
          if (sift == first)
            break;
          sift1--;
          if (tmp >= array[sift1])
            break;
        }
        array[sift] = tmp;
      }
      cur++;
    }
  }

  static void InsertionSort(int[] array, int first, int last)
  {
    if (first == last)
      return;
    UncheckedInsertionSort(array, first, last);
  }

  static void PoplarSift(int[] array, int firstIn, int sizeIn)
  {
    int size = sizeIn;
    if (size < 2)
      return;
    int root = firstIn + (size - 1);
    int childRoot1 = root - 1;
    int childRoot2 = firstIn + (size / 2 - 1);
    while (true)
    {
      int maxRoot = root;
      if (array[maxRoot] < array[childRoot1])
        maxRoot = childRoot1;
      if (array[maxRoot] < array[childRoot2])
        maxRoot = childRoot2;
      if (maxRoot == root)
        return;
      (array[root], array[maxRoot]) = (array[maxRoot], array[root]);
      size /= 2;
      if (size < 2)
        return;
      root = maxRoot;
      childRoot1 = root - 1;
      childRoot2 = maxRoot - (size - size / 2);
    }
  }

  static void PopHeapWithSize(int[] array, int first, int last, int sizeIn)
  {
    int size = sizeIn;
    int poplarSize = Hyperfloor(size + 1) - 1;
    int lastRoot = last - 1;
    int bigger = lastRoot;
    int biggerSize = poplarSize;

    int it = first;
    while (true)
    {
      int root = it + poplarSize - 1;
      if (root == lastRoot)
        break;
      if (array[bigger] < array[root])
      {
        bigger = root;
        biggerSize = poplarSize;
      }
      it = root + 1;
      size -= poplarSize;
      poplarSize = Hyperfloor(size + 1) - 1;
    }

    if (bigger != lastRoot)
    {
      (array[bigger], array[lastRoot]) = (array[lastRoot], array[bigger]);
      PoplarSift(array, bigger - (biggerSize - 1), biggerSize);
    }
  }

  static void MakeHeap(int[] array, int first, int last)
  {
    int size = last - first;
    if (size < 2)
      return;
    int smallPoplarSize = 15;
    if (size <= smallPoplarSize)
    {
      UncheckedInsertionSort(array, first, last);
      return;
    }

    int poplarLevel = 1;
    int it = first;
    int next = it + smallPoplarSize;
    while (true)
    {
      UncheckedInsertionSort(array, it, next);
      int poplarSize = smallPoplarSize;
      int i = (poplarLevel & -poplarLevel) >> 1;
      while (i != 0)
      {
        it -= poplarSize;
        poplarSize = 2 * poplarSize + 1;
        if (it + poplarSize > last)
          break;
        PoplarSift(array, it, poplarSize);
        next++;
        i >>= 1;
      }
      if ((last - next) <= smallPoplarSize)
      {
        InsertionSort(array, next, last);
        return;
      }
      it = next;
      next += smallPoplarSize;
      poplarLevel++;
    }
  }

  static void SortHeap(int[] array, int first, int lastIn)
  {
    int last = lastIn;
    int size = last - first;
    if (size < 2)
      return;
    do
    {
      PopHeapWithSize(array, first, last, size);
      last--;
      size--;
    } while (size > 1);
  }

  static void Sort(int[] array)
  {
    int n = array.Length;
    if (n <= 1)
      return;
    MakeHeap(array, 0, n);
    SortHeap(array, 0, n);
  }

  static void Main()
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    Console.WriteLine("[" + string.Join(", ", array) + "]");
  }
}