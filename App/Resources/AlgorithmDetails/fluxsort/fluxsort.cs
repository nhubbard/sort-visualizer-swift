using System;

public class FluxSort
{
  const int InsertionThreshold = 16;

  static void InsertionSort(int[] arr, int lo, int hi)
  {
    for (int i = lo + 1; i < hi; i++)
    {
      int key = arr[i];
      int j = i - 1;
      while (j >= lo && arr[j] > key)
      {
        arr[j + 1] = arr[j];
        j--;
      }
      arr[j + 1] = key;
    }
  }

  // Returns whichever of a, b, c indexes the middle value of the three.
  static int MedianOfThree(int[] arr, int a, int b, int c)
  {
    if (arr[a] > arr[b])
    {
      int t = a;
      a = b;
      b = t;
    }
    if (arr[b] > arr[c])
    {
      b = c;
      if (arr[a] > arr[b])
      {
        b = a;
      }
    }
    return b;
  }

  static void FluxSortRange(int[] arr, int lo, int hi, int[] swap)
  {
    int n = hi - lo;
    if (n <= InsertionThreshold)
    {
      InsertionSort(arr, lo, hi);
      return;
    }

    int mid = lo + n / 2;
    int pivot = arr[MedianOfThree(arr, lo, mid, hi - 1)];

    // Partition into arr (elements <= pivot) and swap (elements > pivot). Ties go to the
    // low side, which is what keeps the sort stable.
    int lowWrite = lo;
    int highWrite = 0;
    for (int read = lo; read < hi; read++)
    {
      int value = arr[read];
      if (value > pivot)
      {
        swap[highWrite] = value;
        highWrite++;
      }
      else
      {
        arr[lowWrite] = value;
        lowWrite++;
      }
    }

    for (int i = 0; i < highWrite; i++)
    {
      arr[lowWrite + i] = swap[i];
    }

    if (lowWrite == hi)
    {
      // Every element in range was <= pivot -- a run of duplicates around the pivot
      // value can cause this. There's no split to recurse into, so finish directly.
      InsertionSort(arr, lo, hi);
      return;
    }

    FluxSortRange(arr, lo, lowWrite, swap);
    FluxSortRange(arr, lowWrite, hi, swap);
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n < 2) return;
    int[] swap = new int[n];
    FluxSortRange(arr, 0, n, swap);
  }

  public static void Main(String[] args)
  {
    int[] array = {
      55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97,
      15, 62, 34, 79, 21, 88, 5, 51, 66, 29, 44, 12
    };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}