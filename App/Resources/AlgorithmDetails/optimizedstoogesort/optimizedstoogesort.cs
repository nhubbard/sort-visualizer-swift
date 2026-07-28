using System;

public class OptimizedStoogeSort
{
  public static void Forward(int[] arr, int left, int right)
  {
    while (left < right)
    {
      int index = right;
      while (left < index)
      {
        if (arr[left] > arr[index])
        {
          (arr[left], arr[index]) = (arr[index], arr[left]);
        }
        left++;
        index--;
      }
      left = 0;
      right--;
    }
  }

  public static void Backward(int[] arr, int left, int right)
  {
    int length = right;
    while (left < right)
    {
      int index = left;
      while (index < right)
      {
        if (arr[index] > arr[right])
        {
          (arr[index], arr[right]) = (arr[right], arr[index]);
        }
        index++;
        right--;
      }
      left++;
      right = length;
    }
  }

  public static void Exchange(int[] arr, int length)
  {
    int left = 0;
    int right = length - 1;
    while (left < right)
    {
      if (arr[left] > arr[right])
      {
        (arr[left], arr[right]) = (arr[right], arr[left]);
      }
      left++;
      right--;
    }

    Forward(arr, 0, length - 2);
    Backward(arr, 1, length - 1);
  }

  public static void Sort(int[] arr)
  {
    Exchange(arr, arr.Length);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
