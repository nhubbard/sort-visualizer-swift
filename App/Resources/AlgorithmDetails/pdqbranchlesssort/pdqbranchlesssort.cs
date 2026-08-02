using System;

public class PdqBranchlessSort
{
  private const int InsertSortThreshold = 24;
  private const int NintherThreshold = 128;
  private const int PartialInsertSortLimit = 8;
  private const int BlockSize = 64;
  private const int CachelineSize = 64;

  private static int PdqLog(int n)
  {
    int log = 0;
    while ((n >>= 1) != 0) log++;
    return log;
  }

  // Integer division truncated toward zero. C#'s `/` already truncates toward zero for
  // negative operands, which is what the pivot-position arithmetic below needs at the one
  // call site where the dividend can go negative -- this helper just names that intent.
  private static int TruncDiv(int a, int b)
  {
    return a / b;
  }

  private static void InsertSort(int[] arr, int begin, int end)
  {
    for (int cur = begin + 1; cur < end; cur++)
    {
      if (arr[cur] < arr[cur - 1])
      {
        int tmp = arr[cur];
        int sift = cur;
        int siftMinusOne = cur - 1;
        do
        {
          arr[sift--] = arr[siftMinusOne--];
        } while (sift != begin && tmp < arr[siftMinusOne]);
        arr[sift] = tmp;
      }
    }
  }

  private static void UnguardInsertSort(int[] arr, int begin, int end)
  {
    for (int cur = begin + 1; cur < end; cur++)
    {
      if (arr[cur] < arr[cur - 1])
      {
        int tmp = arr[cur];
        int sift = cur;
        int siftMinusOne = cur - 1;
        do
        {
          arr[sift--] = arr[siftMinusOne--];
        } while (tmp < arr[siftMinusOne]);
        arr[sift] = tmp;
      }
    }
  }

  private static bool PartialInsertSort(int[] arr, int begin, int end)
  {
    int limit = 0;
    for (int cur = begin + 1; cur < end; cur++)
    {
      if (limit > PartialInsertSortLimit) return false;
      if (arr[cur] < arr[cur - 1])
      {
        int tmp = arr[cur];
        int sift = cur;
        int siftMinusOne = cur - 1;
        do
        {
          arr[sift--] = arr[siftMinusOne--];
        } while (sift != begin && tmp < arr[siftMinusOne]);
        arr[sift] = tmp;
        limit += cur - sift;
      }
    }
    return true;
  }

  private static void SortTwo(int[] arr, int a, int b)
  {
    if (arr[b] < arr[a]) (arr[a], arr[b]) = (arr[b], arr[a]);
  }

  private static void SortThree(int[] arr, int a, int b, int c)
  {
    SortTwo(arr, a, b);
    SortTwo(arr, b, c);
    SortTwo(arr, a, b);
  }

  private static void SwapOffsets(int[] arr, int first, int last, int[] leftOffsets, int leftPos,
                                   int[] rightOffsets, int rightPos, int num, bool useSwaps)
  {
    if (useSwaps)
    {
      for (int i = 0; i < num; i++)
      {
        (arr[first + leftOffsets[leftPos + i]], arr[last - rightOffsets[rightPos + i]]) =
          (arr[last - rightOffsets[rightPos + i]], arr[first + leftOffsets[leftPos + i]]);
      }
    }
    else if (num > 0)
    {
      int left = first + leftOffsets[leftPos];
      int right = last - rightOffsets[rightPos];
      int tmp = arr[left];
      arr[left] = arr[right];
      for (int i = 1; i < num; i++)
      {
        left = first + leftOffsets[leftPos + i];
        arr[right] = arr[left];
        right = last - rightOffsets[rightPos + i];
        arr[left] = arr[right];
      }
      arr[right] = tmp;
    }
  }

  private static (int pivotPos, bool alreadyParted) PartRightBranchless(int[] arr, int begin, int end,
                                                                         int[] leftOffsets, int[] rightOffsets)
  {
    int pivot = arr[begin];
    int first = begin;
    int last = end;

    first++;
    while (arr[first] < pivot) first++;

    if (first - 1 == begin)
    {
      last--;
      while (first < last && !(arr[last] < pivot)) last--;
    }
    else
    {
      last--;
      while (!(arr[last] < pivot)) last--;
    }

    bool alreadyParted = first >= last;
    if (!alreadyParted)
    {
      (arr[first], arr[last]) = (arr[last], arr[first]);
      first++;
    }

    int leftNum = 0, rightNum = 0, leftStart = 0, rightStart = 0;

    while (last - first > 2 * BlockSize)
    {
      if (leftNum == 0)
      {
        leftStart = 0;
        int it = first;
        for (int i = 0; i < BlockSize; i++)
        {
          leftOffsets[leftNum] = i;
          if (!(arr[it] < pivot)) leftNum++;
          it++;
        }
      }
      if (rightNum == 0)
      {
        rightStart = 0;
        int it = last;
        for (int i = 0; i < BlockSize; i++)
        {
          it--;
          rightOffsets[rightNum] = i + 1;
          if (arr[it] < pivot) rightNum++;
        }
      }

      int num = Math.Min(leftNum, rightNum);
      SwapOffsets(arr, first, last, leftOffsets, leftStart, rightOffsets, rightStart, num, leftNum == rightNum);
      leftNum -= num; rightNum -= num;
      leftStart += num; rightStart += num;
      if (leftNum == 0) first += BlockSize;
      if (rightNum == 0) last -= BlockSize;
    }

    int leftSize = 0, rightSize = 0;
    int unknownLeft = (last - first) - ((rightNum != 0 || leftNum != 0) ? BlockSize : 0);
    if (rightNum != 0)
    {
      leftSize = unknownLeft;
      rightSize = BlockSize;
    }
    else if (leftNum != 0)
    {
      leftSize = BlockSize;
      rightSize = unknownLeft;
    }
    else
    {
      leftSize = TruncDiv(unknownLeft, 2);
      rightSize = unknownLeft - leftSize;
    }

    if (unknownLeft != 0 && leftNum == 0)
    {
      leftStart = 0;
      int it = first;
      for (int i = 0; i < leftSize; i++)
      {
        leftOffsets[leftNum] = i;
        if (!(arr[it] < pivot)) leftNum++;
        it++;
      }
    }

    if (unknownLeft != 0 && rightNum == 0)
    {
      rightStart = 0;
      int it = last;
      for (int i = 0; i < rightSize; i++)
      {
        it--;
        rightOffsets[rightNum] = i + 1;
        if (arr[it] < pivot) rightNum++;
      }
    }

    int num2 = Math.Min(leftNum, rightNum);
    SwapOffsets(arr, first, last, leftOffsets, leftStart, rightOffsets, rightStart, num2, leftNum == rightNum);
    leftNum -= num2; rightNum -= num2;
    leftStart += num2; rightStart += num2;
    if (leftNum == 0) first += leftSize;
    if (rightNum == 0) last -= rightSize;

    int leftOffsetsPos = 0;
    int rightOffsetsPos = 0;

    if (leftNum != 0)
    {
      leftOffsetsPos += leftStart;
      while (leftNum-- != 0)
      {
        last--;
        int src = first + leftOffsets[leftOffsetsPos + leftNum];
        (arr[src], arr[last]) = (arr[last], arr[src]);
      }
      first = last;
    }

    if (rightNum != 0)
    {
      rightOffsetsPos += rightStart;
      while (rightNum-- != 0)
      {
        int src = last - rightOffsets[rightOffsetsPos + rightNum];
        (arr[src], arr[first]) = (arr[first], arr[src]);
        first++;
      }
      last = first;
    }

    int pivotPos = first - 1;
    arr[begin] = arr[pivotPos];
    arr[pivotPos] = pivot;

    return (pivotPos, alreadyParted);
  }

  private static int PartLeft(int[] arr, int begin, int end)
  {
    int pivot = arr[begin];
    int first = begin;
    int last = end;

    last--;
    while (pivot < arr[last]) last--;

    if (last + 1 == end)
    {
      first++;
      while (first < last && !(pivot < arr[first])) first++;
    }
    else
    {
      first++;
      while (!(pivot < arr[first])) first++;
    }

    while (first < last)
    {
      (arr[first], arr[last]) = (arr[last], arr[first]);
      last--;
      while (pivot < arr[last]) last--;
      first++;
      while (!(pivot < arr[first])) first++;
    }

    int pivotPos = last;
    arr[begin] = arr[pivotPos];
    arr[pivotPos] = pivot;
    return pivotPos;
  }

  private static void SiftDown(int[] arr, int begin, int root, int size)
  {
    while (true)
    {
      int child = 2 * root + 1;
      if (child >= size) break;
      if (child + 1 < size && arr[begin + child] < arr[begin + child + 1]) child++;
      if (arr[begin + root] < arr[begin + child])
      {
        (arr[begin + root], arr[begin + child]) = (arr[begin + child], arr[begin + root]);
        root = child;
      }
      else
      {
        break;
      }
    }
  }

  private static void HeapSort(int[] arr, int begin, int end)
  {
    int n = end - begin;
    for (int i = n / 2 - 1; i >= 0; i--) SiftDown(arr, begin, i, n);
    for (int i = n - 1; i > 0; i--)
    {
      (arr[begin], arr[begin + i]) = (arr[begin + i], arr[begin]);
      SiftDown(arr, begin, 0, i);
    }
  }

  private static void PdqLoop(int[] arr, int begin, int end, int badAllowed, int[] leftOffsets, int[] rightOffsets)
  {
    bool leftmost = true;
    while (true)
    {
      int size = end - begin;

      if (size < InsertSortThreshold)
      {
        if (leftmost) InsertSort(arr, begin, end);
        else UnguardInsertSort(arr, begin, end);
        return;
      }

      int halfSize = size / 2;
      if (size > NintherThreshold)
      {
        SortThree(arr, begin, begin + halfSize, end - 1);
        SortThree(arr, begin + 1, begin + halfSize - 1, end - 2);
        SortThree(arr, begin + 2, begin + halfSize + 1, end - 3);
        SortThree(arr, begin + halfSize - 1, begin + halfSize, begin + halfSize + 1);
        (arr[begin], arr[begin + halfSize]) = (arr[begin + halfSize], arr[begin]);
      }
      else
      {
        SortThree(arr, begin + halfSize, begin, end - 1);
      }

      if (!leftmost && !(arr[begin - 1] < arr[begin]))
      {
        begin = PartLeft(arr, begin, end) + 1;
        continue;
      }

      (int pivotPos, bool alreadyParted) = PartRightBranchless(arr, begin, end, leftOffsets, rightOffsets);

      int leftSize = pivotPos - begin;
      int rightSize = end - (pivotPos + 1);
      bool highUnbalance = leftSize < size / 8 || rightSize < size / 8;

      if (highUnbalance)
      {
        if (--badAllowed == 0)
        {
          HeapSort(arr, begin, end);
          return;
        }

        if (leftSize >= InsertSortThreshold)
        {
          (arr[begin], arr[begin + leftSize / 4]) = (arr[begin + leftSize / 4], arr[begin]);
          (arr[pivotPos - 1], arr[pivotPos - leftSize / 4]) = (arr[pivotPos - leftSize / 4], arr[pivotPos - 1]);
          if (leftSize > NintherThreshold)
          {
            (arr[begin + 1], arr[begin + (leftSize / 4 + 1)]) = (arr[begin + (leftSize / 4 + 1)], arr[begin + 1]);
            (arr[begin + 2], arr[begin + (leftSize / 4 + 2)]) = (arr[begin + (leftSize / 4 + 2)], arr[begin + 2]);
            (arr[pivotPos - 2], arr[pivotPos - (leftSize / 4 + 1)]) = (arr[pivotPos - (leftSize / 4 + 1)], arr[pivotPos - 2]);
            (arr[pivotPos - 3], arr[pivotPos - (leftSize / 4 + 2)]) = (arr[pivotPos - (leftSize / 4 + 2)], arr[pivotPos - 3]);
          }
        }

        if (rightSize >= InsertSortThreshold)
        {
          (arr[pivotPos + 1], arr[pivotPos + (1 + rightSize / 4)]) = (arr[pivotPos + (1 + rightSize / 4)], arr[pivotPos + 1]);
          (arr[end - 1], arr[end - rightSize / 4]) = (arr[end - rightSize / 4], arr[end - 1]);
          if (rightSize > NintherThreshold)
          {
            (arr[pivotPos + 2], arr[pivotPos + (2 + rightSize / 4)]) = (arr[pivotPos + (2 + rightSize / 4)], arr[pivotPos + 2]);
            (arr[pivotPos + 3], arr[pivotPos + (3 + rightSize / 4)]) = (arr[pivotPos + (3 + rightSize / 4)], arr[pivotPos + 3]);
            (arr[end - 2], arr[end - (1 + rightSize / 4)]) = (arr[end - (1 + rightSize / 4)], arr[end - 2]);
            (arr[end - 3], arr[end - (2 + rightSize / 4)]) = (arr[end - (2 + rightSize / 4)], arr[end - 3]);
          }
        }
      }
      else
      {
        if (alreadyParted && PartialInsertSort(arr, begin, pivotPos) && PartialInsertSort(arr, pivotPos + 1, end))
        {
          return;
        }
      }

      PdqLoop(arr, begin, pivotPos, badAllowed, leftOffsets, rightOffsets);
      begin = pivotPos + 1;
      leftmost = false;
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    if (n < 2) return;
    int[] leftOffsets = new int[BlockSize + CachelineSize];
    int[] rightOffsets = new int[BlockSize + CachelineSize];
    PdqLoop(arr, 0, n, PdqLog(n), leftOffsets, rightOffsets);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
