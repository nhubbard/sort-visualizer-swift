using System;

public class ExchangeBogoSort
{
  public static Random r = new Random();

  public static bool IsSorted(int[] arr)
  {
    for (int i = 1; i < arr.Length; i++)
    {
      if (arr[i - 1] > arr[i])
      {
        return false;
      }
    }
    return true;
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    while (!IsSorted(arr))
    {
      int i = r.Next(n);
      int j = r.Next(n);
      if ((i < j && arr[i] > arr[j]) || (i > j && arr[i] < arr[j]))
      {
        (arr[i], arr[j]) = (arr[j], arr[i]);
      }
    }
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
