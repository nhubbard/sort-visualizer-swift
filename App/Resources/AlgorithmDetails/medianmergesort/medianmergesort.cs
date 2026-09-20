using System;

public class MedianMergeSort
{
  private static void MergeSort(int[] arr, int[] scratch, int start, int end)
  {
    if (end - start < 2) return;
    int middle = (start + end) / 2;
    MergeSort(arr, scratch, start, middle);
    MergeSort(arr, scratch, middle, end);
    int left = start, right = middle, dest = start;
    while (left < middle && right < end)
      scratch[dest++] = arr[left] <= arr[right] ? arr[left++] : arr[right++];
    while (left < middle) scratch[dest++] = arr[left++];
    while (right < end) scratch[dest++] = arr[right++];
    Array.Copy(scratch, start, arr, start, end - start);
  }

  private static int MedianOfThree(int x, int y, int z)
  {
    if (x > y) { int t = x; x = y; y = t; }
    if (y > z) { int t = y; y = z; z = t; }
    if (x > y) { int t = x; x = y; y = t; }
    return y;
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    int[] scratch = new int[n];
    int start = 0, end = n;
    while (end - start > 16)
    {
      int pivot = MedianOfThree(arr[start], arr[(start + end - 1) / 2], arr[end - 1]);
      int left = start, right = end - 1;
      while (left <= right)
      {
        while (left <= right && arr[left] < pivot) left++;
        while (left <= right && arr[right] > pivot) right--;
        if (left <= right)
        {
          int t = arr[left]; arr[left++] = arr[right]; arr[right--] = t;
        }
      }
      if (left == start || left == end)
      {
        MergeSort(arr, scratch, start, end);
        return;
      }
      if (left - start <= end - left)
      {
        MergeSort(arr, scratch, start, left);
        start = left;
      }
      else
      {
        MergeSort(arr, scratch, left, end);
        end = left;
      }
    }
    for (int i = start + 1; i < end; i++)
    {
      int value = arr[i], j = i;
      while (j > start && arr[j - 1] > value) arr[j] = arr[--j];
      arr[j] = value;
    }
  }

  public static void Main(String[] args)
  {
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56,
      10, 2, 95, 46, 21, 74, 6, 38
    };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}