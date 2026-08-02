using System;

public class BingoSort
{
  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n < 2)
    {
      return;
    }

    // Find the true maximum value in the array.
    int maximum = n - 1;
    int next = arr[maximum];
    for (int i = maximum - 1; i >= 0; i--)
    {
      if (arr[i] > next)
      {
        next = arr[i];
      }
    }
    // Skip past any elements already sitting at the tail with that value.
    while (maximum > 0 && arr[maximum] == next)
    {
      maximum--;
    }

    while (maximum > 0)
    {
      // This round's target is the max found by the previous pass.
      int val = next;
      next = arr[maximum];

      // Sweep once, moving every occurrence of `val` into the shrinking tail
      // while tracking the next-highest value among what's left behind.
      for (int j = maximum - 1; j >= 0; j--)
      {
        if (arr[j] == val)
        {
          int temp = arr[j];
          arr[j] = arr[maximum];
          arr[maximum] = temp;
          maximum--;
        }
        else if (arr[j] > next)
        {
          next = arr[j];
        }
      }

      while (maximum > 0 && arr[maximum] == next)
      {
        maximum--;
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