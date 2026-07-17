using System;

public class CircloidSort
{
  private static bool Circle(int[] arr, int left, int right)
  {
    int a = left;
    int b = right;
    bool swapped = false;
    while (a < b)
    {
      if (arr[a] > arr[b])
      {
        int t = arr[a];
        arr[a] = arr[b];
        arr[b] = t;
        swapped = true;
      }
      a++;
      b--;
      if (a == b)
      {
        b++;
      }
    }
    return swapped;
  }

  private static bool CirclePass(int[] arr, int left, int right)
  {
    if (left >= right)
    {
      return false;
    }
    int mid = (left + right) / 2;
    bool l = CirclePass(arr, left, mid);
    bool r = CirclePass(arr, mid + 1, right);
    return Circle(arr, left, right) || l || r;
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n <= 1)
    {
      return;
    }
    while (CirclePass(arr, 0, n - 1))
    {
      // repeat until a full sweep makes no swaps
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
