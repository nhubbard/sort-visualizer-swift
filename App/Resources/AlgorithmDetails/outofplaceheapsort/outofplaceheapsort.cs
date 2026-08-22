using System;

public class OutOfPlaceHeapSort
{
  static void SiftDown(int[] arr, int root, int size)
  {
    int index = root;
    while (2 * index + 1 < size)
    {
      int child = 2 * index + 1;
      if (child + 1 < size && arr[child + 1] > arr[child])
      {
        child++;
      }
      index = child;
    }
    int rootValue = arr[root];
    while (rootValue > arr[index])
    {
      index = (index - 1) / 2;
    }
    while (index != root)
    {
      (arr[root], arr[index]) = (arr[index], arr[root]);
      index = (index - 1) / 2;
    }
  }

  static void Heapify(int[] arr, int length)
  {
    for (int i = (length - 1) / 2; i >= 0; i--)
    {
      SiftDown(arr, i, length);
    }
  }

  static void FindNext(int[] arr, int size)
  {
    int hole = 0;
    int left = 1;
    int right = 2;
    while (right < size && !(arr[left] == -1 && arr[right] == -1))
    {
      if (arr[left] == -1)
      {
        (arr[hole], arr[right]) = (arr[right], arr[hole]);
        hole = right;
      }
      else if (arr[right] == -1)
      {
        (arr[hole], arr[left]) = (arr[left], arr[hole]);
        hole = left;
      }
      else if (arr[right] > arr[left])
      {
        (arr[hole], arr[right]) = (arr[right], arr[hole]);
        hole = right;
      }
      else
      {
        (arr[hole], arr[left]) = (arr[left], arr[hole]);
        hole = left;
      }
      left = 2 * hole + 1;
      right = left + 1;
    }
    if (left < size && arr[left] != -1)
    {
      (arr[hole], arr[left]) = (arr[left], arr[hole]);
    }
  }

  public static int[] Sort(int[] arr)
  {
    int n = arr.Length;
    int[] output = new int[n];
    if (n <= 1)
    {
      if (n == 1)
      {
        output[0] = arr[0];
      }
      return output;
    }
    Heapify(arr, n);
    for (int i = n - 1; i >= 0; i--)
    {
      output[i] = arr[0];
      arr[0] = -1;
      FindNext(arr, n);
    }
    return output;
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    int[] output = Sort(array);
    string result = "[" + String.Join(", ", output) + "]";
    Console.WriteLine(result);
  }
}