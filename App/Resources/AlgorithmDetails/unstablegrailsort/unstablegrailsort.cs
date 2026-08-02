using System;

public class UnstableGrailSort
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

  public static void InsertSort(int[] arr, int pos, int len)
  {
    for (int i = 1; i < len; i++)
    {
      int j = pos + i;
      while (j > pos && arr[j] < arr[j - 1])
      {
        Swap(arr, j, j - 1);
        j--;
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
    if (len1 + len2 == 2)
    {
      if (arr[pos] > arr[pos + 1]) Swap(arr, pos, pos + 1);
      return;
    }
    int mid1, mid2;
    if (len1 > len2)
    {
      mid1 = len1 / 2;
      mid2 = BinSearch(arr, pos + len1, len2, pos + mid1, true);
    }
    else
    {
      mid2 = len2 / 2;
      mid1 = BinSearch(arr, pos, len1, pos + len1 + mid2, false);
    }
    Rotate(arr, pos + mid1, len1 - mid1, mid2);
    MergeWithoutBuffer(arr, pos, mid1, mid2);
    MergeWithoutBuffer(arr, pos + mid1 + mid2, len1 - mid1, len2 - mid2);
  }

  public static void MergeLeft(int[] arr, int pos, int leftLen, int rightLen, int dist)
  {
    int left = 0;
    int right = leftLen;
    rightLen += leftLen;
    while (right < rightLen)
    {
      if (left == leftLen || arr[pos + left] > arr[pos + right])
      {
        Swap(arr, pos + dist, pos + right); dist++; right++;
      }
      else
      {
        Swap(arr, pos + dist, pos + left); dist++; left++;
      }
    }
    if (dist != left) MultiSwap(arr, pos + dist, pos + left, leftLen - left);
  }

  public static void MergeRight(int[] arr, int pos, int leftLen, int rightLen, int dist)
  {
    int mergedPos = leftLen + rightLen + dist - 1;
    int right = leftLen + rightLen - 1;
    int left = leftLen - 1;
    while (left >= 0)
    {
      if (right < leftLen || arr[pos + left] > arr[pos + right])
      {
        Swap(arr, pos + mergedPos, pos + left); mergedPos--; left--;
      }
      else
      {
        Swap(arr, pos + mergedPos, pos + right); mergedPos--; right--;
      }
    }
    while (right != mergedPos && right >= leftLen)
    {
      Swap(arr, pos + mergedPos, pos + right); mergedPos--; right--;
    }
  }

  public static int SmartMergeWithBuffer(int[] arr, int pos, int leftOverLen, int blockLen)
  {
    int dist = -blockLen;
    int left = 0;
    int right = leftOverLen;
    int leftEnd = right;
    int rightEnd = right + blockLen;
    int length;
    while (left < leftEnd && right < rightEnd)
    {
      if (arr[pos + left] <= arr[pos + right])
      {
        Swap(arr, pos + dist, pos + left); dist++; left++;
      }
      else
      {
        Swap(arr, pos + dist, pos + right); dist++; right++;
      }
    }
    if (left < leftEnd)
    {
      length = leftEnd - left;
      while (left < leftEnd)
      {
        leftEnd--; rightEnd--;
        Swap(arr, pos + leftEnd, pos + rightEnd);
      }
    }
    else
    {
      length = rightEnd - right;
    }
    return length;
  }

  public static void MergeBuffersLeft(int[] arr, int pos, int blockCount, int blockLen, int aBlockCount, int lastLen)
  {
    if (blockCount == 0)
    {
      MergeLeft(arr, pos, aBlockCount * blockLen, lastLen, -blockLen);
      return;
    }
    int leftOverLen = blockLen;
    int processIndex = blockLen;
    for (int keyIndex = 1; keyIndex < blockCount; keyIndex++)
    {
      int restToProcess = processIndex - leftOverLen;
      leftOverLen = SmartMergeWithBuffer(arr, pos + restToProcess, leftOverLen, blockLen);
      processIndex += blockLen;
    }
    int restToProcess2 = processIndex - leftOverLen;
    if (lastLen != 0)
    {
      leftOverLen += blockLen * aBlockCount;
      MergeLeft(arr, pos + restToProcess2, leftOverLen, lastLen, -blockLen);
    }
    else
    {
      MultiSwap(arr, pos + restToProcess2, pos + restToProcess2 - blockLen, leftOverLen);
    }
  }

  public static void BuildBlocks(int[] arr, int pos, int len, int buildLen)
  {
    for (int dist = 1; dist < len; dist += 2)
    {
      int extraDist = (arr[pos + dist - 1] > arr[pos + dist]) ? 1 : 0;
      Swap(arr, pos + dist - 3, pos + dist - 1 + extraDist);
      Swap(arr, pos + dist - 2, pos + dist - extraDist);
    }
    if (len % 2 == 1) Swap(arr, pos + len - 1, pos + len - 3);
    pos -= 2;
    int part = 2;
    while (part < buildLen)
    {
      int left = 0;
      int right = len - 2 * part;
      while (left <= right)
      {
        MergeLeft(arr, pos + left, part, part, -part);
        left += 2 * part;
      }
      int rest = len - left;
      if (rest > part) MergeLeft(arr, pos + left, part, rest - part, -part);
      else Rotate(arr, pos + left - part, part, rest);
      pos -= part;
      part *= 2;
    }
    int restToBuild = len % (2 * buildLen);
    int leftOverPos = len - restToBuild;
    if (restToBuild <= buildLen) Rotate(arr, pos + leftOverPos, restToBuild, buildLen);
    else MergeRight(arr, pos + leftOverPos, buildLen, restToBuild - buildLen, buildLen);
    while (leftOverPos > 0)
    {
      leftOverPos -= 2 * buildLen;
      MergeRight(arr, pos + leftOverPos, buildLen, buildLen, buildLen);
    }
  }

  public static void CombineBlocks(int[] arr, int pos, int len, int buildLen, int regBlockLen)
  {
    int combineLen = len / (2 * buildLen);
    int leftOver = len % (2 * buildLen);
    if (leftOver <= buildLen)
    {
      len -= leftOver;
      leftOver = 0;
    }
    for (int i = 0; i <= combineLen; i++)
    {
      if (i == combineLen && leftOver == 0) break;
      int blockPos = pos + i * 2 * buildLen;
      int blockCount = (i == combineLen ? leftOver : 2 * buildLen) / regBlockLen;
      for (int index = 1; index < blockCount; index++)
      {
        int leftIndex = index - 1;
        for (int rightIndex = index; rightIndex < blockCount; rightIndex++)
        {
          int a = arr[blockPos + leftIndex * regBlockLen];
          int b = arr[blockPos + rightIndex * regBlockLen];
          int cmp = a.CompareTo(b);
          if (cmp > 0 || (cmp == 0 && arr[blockPos + (leftIndex + 1) * regBlockLen - 1] >
                                           arr[blockPos + (rightIndex + 1) * regBlockLen - 1]))
          {
            leftIndex = rightIndex;
          }
        }
        if (leftIndex != index - 1)
        {
          MultiSwap(arr, blockPos + (index - 1) * regBlockLen, blockPos + leftIndex * regBlockLen, regBlockLen);
        }
      }
      int aBlockCount = 0;
      int lastLen = (i == combineLen) ? (leftOver % regBlockLen) : 0;
      if (lastLen != 0)
      {
        while (aBlockCount < blockCount &&
               arr[blockPos + blockCount * regBlockLen] < arr[blockPos + (blockCount - aBlockCount - 1) * regBlockLen])
        {
          aBlockCount++;
        }
      }
      MergeBuffersLeft(arr, blockPos, blockCount - aBlockCount, regBlockLen, aBlockCount, lastLen);
    }
    while (len > 0)
    {
      len--;
      Swap(arr, pos + len, pos + len - regBlockLen);
    }
  }

  public static void CommonSort(int[] arr, int pos, int len)
  {
    if (len <= 16)
    {
      InsertSort(arr, pos, len);
      return;
    }
    int blockLen = 1;
    while (blockLen * blockLen < len) blockLen *= 2;
    int buildLen = blockLen;
    BuildBlocks(arr, pos + blockLen, len - blockLen, buildLen);
    while (true)
    {
      buildLen *= 2;
      if (len - blockLen <= buildLen) break;
      CombineBlocks(arr, pos + blockLen, len - blockLen, buildLen, blockLen);
    }
    InsertSort(arr, pos, blockLen);
    MergeWithoutBuffer(arr, pos, blockLen, len - blockLen);
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    CommonSort(arr, 0, n);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
