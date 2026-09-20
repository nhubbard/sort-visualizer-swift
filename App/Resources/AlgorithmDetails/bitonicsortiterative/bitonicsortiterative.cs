using System;

public class BitonicSort
{
  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    for (int k = 2; k < 2 * n; k *= 2)
    {
      bool m = ((n + k - 1) / k) % 2 != 0;
      for (int j = k / 2; j > 0; j /= 2)
      {
        for (int i = 0; i < n; i++)
        {
          int l = i ^ j;
          if (l > i && l < n)
          {
            bool ascending = ((i & k) == 0) == m;
            if ((ascending && arr[i] > arr[l]) || (!ascending && arr[i] < arr[l]))
            {
              (arr[i], arr[l]) = (arr[l], arr[i]);
            }
          }
        }
      }
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
