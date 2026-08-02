using System;

public class TableSort
{
  public static bool StableComp(int[] arr, int[] table, int a, int b)
  {
    int ta = table[a];
    int tb = table[b];
    if (arr[ta] > arr[tb]) return true;
    if (arr[ta] == arr[tb]) return table[a] > table[b];
    return false;
  }

  public static void MedianOfThree(int[] arr, int[] table, int a, int b)
  {
    int m = a + (b - 1 - a) / 2;
    if (StableComp(arr, table, a, m)) (table[a], table[m]) = (table[m], table[a]);
    if (StableComp(arr, table, m, b - 1))
    {
      (table[m], table[b - 1]) = (table[b - 1], table[m]);
      if (StableComp(arr, table, a, m)) return;
    }
    (table[a], table[m]) = (table[m], table[a]);
  }

  public static int Partition(int[] arr, int[] table, int a, int b, int p)
  {
    int i = a - 1;
    int j = b;
    while (true)
    {
      do
      {
        i++;
      } while (i < j && !StableComp(arr, table, i, p));
      do
      {
        j--;
      } while (j >= i && StableComp(arr, table, j, p));
      if (i < j)
      {
        (table[i], table[j]) = (table[j], table[i]);
      }
      else
      {
        return j;
      }
    }
  }

  public static void QuickSort(int[] arr, int[] table, int a, int b)
  {
    if (b - a < 3)
    {
      if (b - a == 2 && StableComp(arr, table, a, a + 1))
      {
        (table[a], table[a + 1]) = (table[a + 1], table[a]);
      }
      return;
    }
    MedianOfThree(arr, table, a, b);
    int p = Partition(arr, table, a + 1, b, a);
    (table[a], table[p]) = (table[p], table[a]);
    QuickSort(arr, table, a, p);
    QuickSort(arr, table, p + 1, b);
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    int[] table = new int[n];
    for (int i = 0; i < n; i++) table[i] = i;
    QuickSort(arr, table, 0, n);
    for (int i = 0; i < n; i++)
    {
      if (table[i] != i)
      {
        int t = arr[i];
        int j = i;
        int next = table[i];
        do
        {
          arr[j] = arr[next];
          table[j] = j;
          j = next;
          next = table[next];
        } while (next != i);
        arr[j] = t;
        table[j] = j;
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