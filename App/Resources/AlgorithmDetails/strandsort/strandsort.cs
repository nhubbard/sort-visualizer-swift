using System;

public class StrandSort
{
  public static void MergeTo(int[] arr, int[] subList, int a, int m, int b)
  {
    int i = 0;
    int s = m - a;
    while (i < s && m < b)
    {
      if (subList[i] < arr[m])
      {
        arr[a] = subList[i];
        a++;
        i++;
      }
      else
      {
        arr[a] = arr[m];
        a++;
        m++;
      }
    }
    while (i < s)
    {
      arr[a] = subList[i];
      a++;
      i++;
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n < 2)
      return;

    int[] subList = new int[n];

    int j = n;
    int k = j;
    while (j > 0)
    {
      subList[0] = arr[0];
      k--;

      int i = 0;
      int p = 0;
      for (int m = 1; m < j; m++)
      {
        if (arr[m] >= subList[i])
        {
          i++;
          subList[i] = arr[m];
          k--;
        }
        else
        {
          arr[p] = arr[m];
          p++;
        }
      }

      MergeTo(arr, subList, k, j, n);
      j = k;
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