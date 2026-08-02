using System;

public class BlockInsertionSort
{
  public static void MultiSwap(int[] arr, int a, int b, int count)
  {
    for (int i = 0; i < count; i++)
    {
      (arr[a + i], arr[b + i]) = (arr[b + i], arr[a + i]);
    }
  }

  public static void Rotate(int[] arr, int pos, int lenA, int lenB)
  {
    while (lenA != 0 && lenB != 0)
    {
      if (lenA <= lenB)
      {
        MultiSwap(arr, pos, pos + lenA, lenA);
        pos += lenA;
        lenB -= lenA;
      }
      else
      {
        MultiSwap(arr, pos + (lenA - lenB), pos + lenA, lenB);
        lenA -= lenB;
      }
    }
  }

  public static int BinSearch(int[] arr, int pos, int len, int keyPos, bool isLeft)
  {
    int left = 0, right = len;
    while (left < right)
    {
      int mid = left + (right - left) / 2;
      bool cond = isLeft ? arr[pos + mid] < arr[keyPos] : arr[pos + mid] <= arr[keyPos];
      if (cond) left = mid + 1;
      else right = mid;
    }
    return left;
  }

  public static void MergeWithoutBuffer(int[] arr, int pos, int len1, int len2)
  {
    if (len1 == 0 || len2 == 0) return;
    if (len1 == 1)
    {
      int loc = BinSearch(arr, pos + 1, len2, pos, true);
      Rotate(arr, pos, 1, loc);
      return;
    }
    if (len2 == 1)
    {
      int loc = BinSearch(arr, pos, len1, pos + len1, false);
      Rotate(arr, pos + loc, len1 - loc, 1);
      return;
    }
    int mid1 = len1 / 2;
    int loc2 = BinSearch(arr, pos + len1, len2, pos + mid1, true);
    Rotate(arr, pos + mid1, len1 - mid1, loc2);
    MergeWithoutBuffer(arr, pos, mid1, loc2);
    MergeWithoutBuffer(arr, pos + mid1 + loc2, len1 - mid1, len2 - loc2);
  }

  public static int FindRun(int[] arr, int a, int b)
  {
    int i = a + 1;
    if (i == b) return i;
    if (arr[i - 1] > arr[i])
    {
      i++;
      while (i < b && arr[i - 1] > arr[i]) i++;
      int lo = a, hi = i - 1;
      while (lo < hi)
      {
        (arr[lo], arr[hi]) = (arr[hi], arr[lo]);
        lo++;
        hi--;
      }
    }
    else
    {
      i++;
      while (i < b && arr[i - 1] <= arr[i]) i++;
    }
    return i;
  }

  public static void Insert1(int[] arr, int a, int l)
  {
    int tmp = arr[l];
    l--;
    while (l >= a && arr[l] > tmp)
    {
      arr[l + 1] = arr[l];
      l--;
    }
    arr[l + 1] = tmp;
  }

  public static void Insert2(int[] arr, int a, int l, int r)
  {
    int tmpL = arr[l];
    int tmpR = arr[r];
    l--;
    while (l >= a && arr[l] > tmpR)
    {
      arr[l + 2] = arr[l];
      l--;
    }
    arr[l + 2] = tmpR;
    while (l >= a && arr[l] > tmpL)
    {
      arr[l + 1] = arr[l];
      l--;
    }
    arr[l + 1] = tmpL;
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    int i = FindRun(arr, 0, n);
    while (i < n)
    {
      int j = FindRun(arr, i, n);
      int len = j - i;
      if (len == 1) Insert1(arr, 0, i);
      else if (len == 2) Insert2(arr, 0, i, i + 1);
      else MergeWithoutBuffer(arr, 0, i, len);
      i = j;
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
