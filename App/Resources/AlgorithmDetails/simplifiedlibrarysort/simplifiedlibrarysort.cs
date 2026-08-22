using System;

public class SimplifiedLibrarySort
{
  private static int BinarySearch(int[] arr, int item, int start, int end)
  {
    var lo = start;
    var hi = end;
    while (lo < hi)
    {
      var mid = lo + (hi - lo) / 2;
      if (item < arr[mid])
      {
        hi = mid;
      }
      else
      {
        lo = mid + 1;
      }
    }
    return lo;
  }

  private static void BinaryInsertionSort(int[] arr, int start, int end)
  {
    for (var i = start + 1; i < end; i++)
    {
      var item = arr[i];
      var pos = BinarySearch(arr, item, start, i);
      var j = i;
      while (j > pos)
      {
        arr[j] = arr[j - 1];
        j--;
      }
      arr[pos] = item;
    }
  }

  private static void Rebalance(
    int[] arr,
    int[] temp,
    int[] counts,
    int[] locations,
    int spineSize,
    int batchEnd
  )
  {
    for (var i = 0; i < spineSize; i++)
    {
      counts[i + 1] = counts[i + 1] + counts[i] + 1;
    }

    var k = 0;
    for (var i = spineSize; i < batchEnd; i++)
    {
      var gap = locations[k];
      var position = counts[gap];
      temp[position] = arr[i];
      counts[gap] = position + 1;
      k++;
    }

    for (var i = 0; i < spineSize; i++)
    {
      var position = counts[i];
      temp[position] = arr[i];
      counts[i] = position + 1;
    }

    for (var i = 0; i < batchEnd; i++)
    {
      arr[i] = temp[i];
    }

    BinaryInsertionSort(arr, 0, counts[0] - 1);
    for (var i = 0; i < spineSize - 1; i++)
    {
      BinaryInsertionSort(arr, counts[i], counts[i + 1] - 1);
    }
    BinaryInsertionSort(arr, counts[spineSize - 1], counts[spineSize]);

    for (var i = 0; i < spineSize + 2; i++)
    {
      counts[i] = 0;
    }
  }

  private static void LibrarySort(int[] arr)
  {
    var n = arr.Length;
    if (n < 2)
    {
      return;
    }

    var rebalanceFactor = 2;
    var spineSize = 1;
    BinaryInsertionSort(arr, 0, spineSize);

    var maxLevel = spineSize;
    while (maxLevel * rebalanceFactor < n)
    {
      maxLevel *= rebalanceFactor;
    }

    var temp = new int[n];
    var counts = new int[maxLevel + 2];
    var locations = new int[n];

    var i = spineSize;
    var k = 0;
    while (i < n)
    {
      if (rebalanceFactor * spineSize == i)
      {
        Rebalance(arr, temp, counts, locations, spineSize, i);
        spineSize = i;
        k = 0;
      }
      var gap = BinarySearch(arr, arr[i], 0, spineSize);
      counts[gap + 1]++;
      locations[k] = gap;
      k++;
      i++;
    }
    Rebalance(arr, temp, counts, locations, spineSize, n);
  }

  public static int[] Sort(int[] array)
  {
    LibrarySort(array);
    return array;
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    array = Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}