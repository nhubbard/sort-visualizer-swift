using System;

public class OddEvenMergeSortIterative
{
  public static void Sort(int[] arr)
  {
    int n = arr.Length;

    for (int p = 1; p < n; p += p)
    {
      for (int k = p; k > 0; k /= 2)
      {
        for (int j = k % p; j + k < n; j += k + k)
        {
          for (int i = 0; i < k; i++)
          {
            if ((i + j) / (p + p) == (i + j + k) / (p + p))
            {
              if (i + j + k < n)
              {
                if (arr[i + j] > arr[i + j + k])
                {
                  (arr[i + j], arr[i + j + k]) = (arr[i + j + k], arr[i + j]);
                }
              }
            }
          }
        }
      }
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
