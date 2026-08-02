using System;

public class LazyStableSort
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

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    int dist = 1;
    while (dist < n)
    {
      if (arr[dist - 1] > arr[dist]) (arr[dist - 1], arr[dist]) = (arr[dist], arr[dist - 1]);
      dist += 2;
    }
    int part = 2;
    while (part < n)
    {
      int left = 0;
      int right = n - 2 * part;
      while (left <= right)
      {
        MergeWithoutBuffer(arr, left, part, part);
        left += 2 * part;
      }
      int rest = n - left;
      if (rest > part) MergeWithoutBuffer(arr, left, part, rest - part);
      part *= 2;
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