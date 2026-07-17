using System;

public class GuessSort
{
  public static bool IsValid(int[] arr, int[] loops, int n)
  {
    int total = 0;
    for (int i = 0; i < n; i++)
    {
      for (int j = 0; j < n; j++)
      {
        if (loops[i] == loops[j])
        {
          total += 1;
        }
      }
    }
    for (int i = 0; i < n; i++)
    {
      for (int j = 0; j < n; j++)
      {
        if (i < j && arr[loops[i]] > arr[loops[j]])
        {
          total += 1;
        }
        else if (i > j && arr[loops[i]] < arr[loops[j]])
        {
          total += 1;
        }
      }
    }
    return total == n;
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    int[] loops = new int[n];
    int[] indexes = new int[n];

    while (true)
    {
      if (IsValid(arr, loops, n))
      {
        Array.Copy(loops, indexes, n);
      }
      int pos = 0;
      while (pos < n)
      {
        if (loops[pos] < n - 1)
        {
          loops[pos] += 1;
          break;
        }
        else
        {
          loops[pos] = 0;
          pos += 1;
        }
      }
      if (pos == n)
      {
        break;
      }
    }

    int[] original = (int[])arr.Clone();
    for (int i = 0; i < n; i++)
    {
      arr[i] = original[indexes[i]];
    }
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 14 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
