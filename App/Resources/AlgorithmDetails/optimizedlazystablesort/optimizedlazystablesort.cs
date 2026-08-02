using System;

public class OptimizedLazyStableSort
{
  public static void Swap(int[] arr, int a, int b)
  {
    (arr[a], arr[b]) = (arr[b], arr[a]);
  }

  public static void MultiSwap(int[] arr, int a, int b, int count)
  {
    for (int i = 0; i < count; i++) Swap(arr, a + i, b + i);
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
    int left = -1;
    int right = len;
    int key = arr[keyPos];
    while (left < right - 1)
    {
      int mid = left + (right - left) / 2;
      bool cond = isLeft ? (arr[pos + mid] >= key) : (arr[pos + mid] > key);
      if (cond) right = mid; else left = mid;
    }
    return right;
  }

  public static void MergeWithoutBuffer(int[] arr, int pos, int len1, int len2)
  {
    if (len1 == 0 || len2 == 0) return;
    if (len1 < len2)
    {
      while (len1 != 0)
      {
        int loc = BinSearch(arr, pos + len1, len2, pos, true);
        if (loc != 0)
        {
          Rotate(arr, pos, len1, loc);
          pos += loc;
          len2 -= loc;
        }
        if (len2 == 0) break;
        do
        {
          pos++;
          len1--;
        } while (len1 != 0 && arr[pos] <= arr[pos + len1]);
      }
    }
    else
    {
      while (len2 != 0)
      {
        int loc = BinSearch(arr, pos, len1, pos + len1 + len2 - 1, false);
        if (loc != len1)
        {
          Rotate(arr, pos + loc, len1 - loc, len2);
          len1 = loc;
        }
        if (len1 == 0) break;
        do
        {
          len2--;
        } while (len2 != 0 && arr[pos + len1 - 1] <= arr[pos + len1 + len2 - 1]);
      }
    }
  }

  // Guard: a chunk of length <= 1 has nothing to compare. ArrayV's own source skips this
  // check and unconditionally reads arr[a] / arr[a + 1], which crashes whenever chunking
  // leaves a trailing 1-element chunk (e.g. n = 17 leaves a final [16, 17) chunk).
  public static void InsertionSortChunk(int[] arr, int a, int b)
  {
    if (b - a <= 1) return;
    int i = a + 1;
    bool descending = arr[i - 1] > arr[i];
    i++;
    if (descending)
    {
      while (i < b && arr[i - 1] > arr[i]) i++;
      int lo = a, hi = i - 1;
      while (lo < hi)
      {
        Swap(arr, lo, hi);
        lo++;
        hi--;
      }
    }
    else
    {
      while (i < b && arr[i - 1] <= arr[i]) i++;
    }
    while (i < b)
    {
      int current = arr[i];
      int pos = i - 1;
      while (pos >= a && arr[pos] > current)
      {
        arr[pos + 1] = arr[pos];
        pos--;
      }
      arr[pos + 1] = current;
      i++;
    }
  }

  public static void LazyStableSort(int[] arr, int pos, int len)
  {
    int dist = 0;
    while (dist + 16 < len)
    {
      InsertionSortChunk(arr, pos + dist, pos + dist + 16);
      dist += 16;
    }
    if (dist < len) InsertionSortChunk(arr, pos + dist, pos + len);

    int part = 16;
    while (part < len)
    {
      int left = 0;
      int right = len - 2 * part;
      while (left <= right)
      {
        MergeWithoutBuffer(arr, pos + left, part, part);
        left += 2 * part;
      }
      int rest = len - left;
      if (rest > part) MergeWithoutBuffer(arr, pos + left, part, rest - part);
      part *= 2;
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    LazyStableSort(arr, 0, n);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
