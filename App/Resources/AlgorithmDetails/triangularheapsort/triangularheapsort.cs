using System;

class TriangularHeapSort
{
  static int TriangularRoot(int val)
  {
    return ((int)Math.Sqrt((double)(8 * val + 1)) - 1) / 2;
  }

  static void SiftDown(int[] array, int root, int size)
  {
    while (true)
    {
      int row = TriangularRoot(root);
      int left = root + row + 1;
      if (left >= size)
        break;
      int right = left + 1;
      int largest = root;
      if (array[largest] < array[left])
        largest = left;
      if (right < size && array[largest] < array[right])
        largest = right;
      if (largest == root)
        break;
      (array[root], array[largest]) = (array[largest], array[root]);
      root = largest;
    }
  }

  static void Heapify(int[] array, int length)
  {
    for (int i = length - 1; i >= 0; i--)
    {
      SiftDown(array, i, length);
    }
  }

  static void Sort(int[] array)
  {
    int n = array.Length;
    if (n <= 1)
      return;
    Heapify(array, n);
    for (int i = 1; i < n - 1; i++)
    {
      (array[0], array[n - i]) = (array[n - i], array[0]);
      SiftDown(array, 0, n - i);
    }
    if (array[0] > array[1])
    {
      (array[0], array[1]) = (array[1], array[0]);
    }
  }

  static void Main()
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    Console.WriteLine("[" + string.Join(", ", array) + "]");
  }
}
