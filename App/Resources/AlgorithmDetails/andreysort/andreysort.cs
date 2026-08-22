using System;

public class AndreySort
{
  private static void Swap(int[] arr, int i, int j)
  {
    int t = arr[i];
    arr[i] = arr[j];
    arr[j] = t;
  }

  // Base case below length 12: repeatedly swap the minimum of the remaining
  // range to the front.
  private static void SelectionSort(int[] arr, int a, int b)
  {
    while (b > 1)
    {
      int k = 0;
      for (int i = 1; i < b; i++)
      {
        if (arr[a + k] > arr[a + i])
        {
          k = i;
        }
      }
      Swap(arr, a, a + k);
      a++;
      b--;
    }
  }

  // Forward block-swap of l elements.
  private static void ASwap(int[] arr, int arr1, int arr2, int l)
  {
    while (l > 0)
    {
      Swap(arr, arr1, arr2);
      arr1++;
      arr2++;
      l--;
    }
  }

  // Merges the two runs ending at arr1/arr2 (lengths l1/l2), working backward
  // from their high ends into the trailing buffer that starts right after
  // arr2. Returns the count of unplaced left-run elements if the right run
  // ran out first (0 otherwise).
  private static int Backmerge(int[] arr, int arr1, int l1, int arr2, int l2)
  {
    int arr0 = arr2 + l1;
    while (true)
    {
      if (arr[arr1] > arr[arr2])
      {
        Swap(arr, arr1, arr0);
        arr1--;
        arr0--;
        l1--;
        if (l1 == 0)
        {
          return 0;
        }
      }
      else
      {
        Swap(arr, arr2, arr0);
        arr2--;
        arr0--;
        l2--;
        if (l2 == 0)
        {
          break;
        }
      }
    }
    int res = l1;
    do
    {
      Swap(arr, arr1, arr0);
      arr1--;
      arr0--;
      l1--;
    } while (l1 != 0);
    return res;
  }

  // Merges arr[a..a+l) (as l/r blocks of width r) using the buffer
  // arr[a+l..a+l+r): selection-sorts the block leaders, then backmerges each
  // selected block into place.
  private static void RMerge(int[] arr, int a, int l, int r)
  {
    int i = 0;
    while (i < l)
    {
      int q = i;
      int j = i + r;
      while (j < l)
      {
        if (arr[a + q] > arr[a + j])
        {
          q = j;
        }
        j += r;
      }
      if (q != i)
      {
        ASwap(arr, a + i, a + q, r);
      }
      if (i != 0)
      {
        ASwap(arr, a + l, a + i, r);
        Backmerge(arr, a + (l + r - 1), r, a + (i - 1), r);
      }
      i += r;
    }
  }

  // Computes the block size: roughly sqrt(len), rounded up to a power of two.
  private static int RBnd(int len)
  {
    len /= 2;
    int k = 0;
    int i = 1;
    while (i < len)
    {
      k++;
      i *= 2;
    }
    len /= k;
    k = 1;
    while (k <= len)
    {
      k *= 2;
    }
    return k;
  }

  private static void MSort(int[] arr, int a, int len)
  {
    if (len < 12)
    {
      SelectionSort(arr, a, len);
      return;
    }

    int r = RBnd(len);
    int lr = (len / r - 1) * r;

    int p = 2;
    while (p <= lr)
    {
      if (arr[a + (p - 2)] > arr[a + (p - 1)])
      {
        Swap(arr, a + (p - 2), a + (p - 1));
      }
      if ((p & 2) != 0)
      {
        p += 2;
        continue;
      }

      ASwap(arr, a + (p - 2), a + p, 2);

      int m = len - p;
      int q = 2;
      while (true)
      {
        int q0 = 2 * q;
        if (q0 > m || (p & q0) != 0)
        {
          break;
        }
        Backmerge(arr, a + (p - q - 1), q, a + (p + q - 1), q);
        q = q0;
      }
      Backmerge(arr, a + (p + q - 1), q, a + (p - q - 1), q);
      int q1 = q;
      q *= 2;

      while ((q & p) == 0)
      {
        q *= 2;
        RMerge(arr, a + (p - q), q, q1);
      }

      p += 2;
    }

    int rq1 = 0;
    int rq = r;
    while (rq < lr)
    {
      if ((lr & rq) != 0)
      {
        rq1 += rq;
        if (rq1 != rq)
        {
          RMerge(arr, a + (lr - rq1), rq1, r);
        }
      }
      rq *= 2;
    }

    int s0 = len - lr;
    MSort(arr, a + lr, s0);
    ASwap(arr, a, a + lr, s0);
    int s = s0 + Backmerge(arr, a + (s0 - 1), s0, a + (lr - 1), lr - s0);
    MSort(arr, a, s);
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    MSort(arr, 0, n);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}