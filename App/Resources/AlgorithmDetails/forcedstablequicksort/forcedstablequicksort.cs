using System;

public class ForcedStableQuickSort
{
  private static bool StableComp(int[] arr, int[] key, int a, int b)
  {
    if (arr[a] > arr[b]) return true;
    if (arr[a] == arr[b]) return key[a] > key[b];
    return false;
  }

  private static void StableSwap(int[] arr, int[] key, int a, int b)
  {
    (arr[a], arr[b]) = (arr[b], arr[a]);
    (key[a], key[b]) = (key[b], key[a]);
  }

  private static void MedianOfThree(int[] arr, int[] key, int a, int b)
  {
    int m = a + (b - 1 - a) / 2;
    if (StableComp(arr, key, a, m)) StableSwap(arr, key, a, m);
    if (StableComp(arr, key, m, b - 1))
    {
      StableSwap(arr, key, m, b - 1);
      if (StableComp(arr, key, a, m)) return;
    }
    StableSwap(arr, key, a, m);
  }

  private static int Partition(int[] arr, int[] key, int a, int b, int p)
  {
    int i = a - 1;
    int j = b;
    while (true)
    {
      do
      {
        i++;
      } while (i < j && !StableComp(arr, key, i, p));
      do
      {
        j--;
      } while (j >= i && StableComp(arr, key, j, p));
      if (i < j)
      {
        StableSwap(arr, key, i, j);
      }
      else
      {
        return j;
      }
    }
  }

  private static void QuickSort(int[] arr, int[] key, int a, int b)
  {
    if (b - a < 3)
    {
      if (b - a == 2 && StableComp(arr, key, a, a + 1)) StableSwap(arr, key, a, a + 1);
      return;
    }
    MedianOfThree(arr, key, a, b);
    int p = Partition(arr, key, a + 1, b, a);
    StableSwap(arr, key, a, p);
    QuickSort(arr, key, a, p);
    QuickSort(arr, key, p + 1, b);
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    int[] key = new int[n];
    for (int i = 0; i < n; i++) key[i] = i;
    QuickSort(arr, key, 0, n);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
