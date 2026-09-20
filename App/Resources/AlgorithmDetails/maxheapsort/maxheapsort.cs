using System;

public class HeapSort
{
  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    for (int i = n / 2 - 1; i >= 0; i--)
    {
      SiftDown(arr, i, n);
    }
    for (int i = n - 1; i > 0; i--)
    {
      (arr[0], arr[i]) = (arr[i], arr[0]);
      SiftDown(arr, 0, i);
    }
  }

  private static void SiftDown(int[] arr, int root, int size)
  {
    while (true)
    {
      int largest = root;
      int left = 2 * root + 1;
      int right = left + 1;
      if (left < size && arr[largest] < arr[left]) largest = left;
      if (right < size && arr[largest] < arr[right]) largest = right;
      if (largest == root) break;
      (arr[root], arr[largest]) = (arr[largest], arr[root]);
      root = largest;
    }
  }

  public static void Main(String[] args)
  {
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56
    };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
