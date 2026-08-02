using System;

public class SelectionBogoSort
{
  public static Random r = new Random();

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    for (int i = 0; i < n; i++)
    {
      while (arr[i] != Min(arr, i))
      {
        int j = r.Next(i, n);
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
      }
    }
  }

  public static int Min(int[] arr, int i)
  {
    int m = arr[i];
    for (int k = i + 1; k < arr.Length; k++)
    {
      if (arr[k] < m)
      {
        m = arr[k];
      }
    }
    return m;
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 14, 23 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}