using System;

public class RandomGuessSort
{
  public static Random r = new Random();

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    int[] loops = new int[n];
    while (true)
    {
      bool isSorted = true;
      for (int i = 0; i < n - 1; i++)
      {
        int a = arr[loops[i]];
        int b = arr[loops[i + 1]];
        if (a < b || (a == b && loops[i] < loops[i + 1]))
        {
          continue;
        }
        isSorted = false;
        break;
      }
      if (isSorted)
      {
        break;
      }
      for (int pos = 0; pos < n; pos++)
      {
        loops[pos] = r.Next(n);
      }
    }

    int[] mapped = new int[n];
    for (int i = 0; i < n; i++)
    {
      mapped[i] = arr[loops[i]];
    }
    for (int i = 0; i < n; i++)
    {
      arr[i] = mapped[i];
    }
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 14 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}