using System;

public class BufferPartitionMergeSort
{
  public static void Sort(int[] arr)
  {
    const int run = 8;
    for (int start = 0; start < arr.Length; start += run)
    {
      int end = Math.Min(start + run, arr.Length);
      for (int i = start + 1; i < end; i++)
      {
        int value = arr[i];
        int j = i;
        while (j > start && arr[j - 1] > value)
        {
          arr[j] = arr[j - 1];
          j--;
        }
        arr[j] = value;
      }
    }

    int[] scratch = (int[])arr.Clone();
    for (int width = run; width < arr.Length; width *= 2)
    {
      for (int start = 0; start < arr.Length; start += 2 * width)
      {
        int middle = Math.Min(start + width, arr.Length);
        int end = Math.Min(start + 2 * width, arr.Length);
        int left = start;
        int right = middle;
        for (int output = start; output < end; output++)
        {
          if (left < middle && (right >= end || arr[left] < arr[right]))
            scratch[output] = arr[left++];
          else
            scratch[output] = arr[right++];
        }
      }
      Array.Copy(scratch, arr, arr.Length);
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
