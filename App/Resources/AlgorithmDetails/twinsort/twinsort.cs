using System;

public class TwinSort
{
  private static void ReverseRange(int[] arr, int lo, int hi)
  {
    while (lo < hi)
    {
      (arr[lo], arr[hi]) = (arr[hi], arr[lo]);
      lo++;
      hi--;
    }
  }

  private static int TwinSwap(int[] arr, int nmemb)
  {
    int index = 0;
    int end = nmemb - 2;
    while (index <= end)
    {
      if (arr[index] <= arr[index + 1])
      {
        index += 2;
        continue;
      }
      int start = index;
      index += 2;
      while (true)
      {
        if (index > end)
        {
          if (start == 0 && (nmemb % 2 == 0 || arr[index - 1] > arr[index]))
          {
            end = nmemb - 1;
            ReverseRange(arr, start, end);
            return 1;
          }
          break;
        }
        if (arr[index] > arr[index + 1])
        {
          if (arr[index - 1] > arr[index])
          {
            index += 2;
            continue;
          }
          (arr[index], arr[index + 1]) = (arr[index + 1], arr[index]);
        }
        break;
      }
      end = index - 1;
      ReverseRange(arr, start, end);
      end = nmemb - 2;
      index += 2;
    }
    return 0;
  }

  private static void TailMerge(int[] arr, int[] buf, int nmemb, int block)
  {
    int s = 0;
    while (block < nmemb)
    {
      int offset = 0;
      while (offset + block < nmemb)
      {
        int a = offset;
        int e = a + block - 1;
        if (arr[e] <= arr[e + 1])
        {
          offset += block * 2;
          continue;
        }
        int cMax, dMax;
        if (offset + block * 2 <= nmemb)
        {
          cMax = s + block;
          dMax = a + block * 2;
        }
        else
        {
          cMax = s + nmemb - (offset + block);
          dMax = nmemb;
        }
        int d = dMax - 1;
        while (arr[e] <= arr[d])
        {
          dMax--;
          d--;
          cMax--;
        }
        int c = s;
        d = a + block;
        while (c < cMax)
        {
          buf[c] = arr[d];
          c++;
          d++;
        }
        c--;
        d = a + block - 1;
        e = dMax - 1;
        if (arr[a] <= arr[a + block])
        {
          arr[e] = arr[d]; e--; d--;
          while (c >= s)
          {
            while (arr[d] > buf[c])
            {
              arr[e] = arr[d]; e--; d--;
            }
            arr[e] = buf[c]; e--; c--;
          }
        }
        else
        {
          arr[e] = arr[d]; e--; d--;
          while (d >= a)
          {
            while (arr[d] <= buf[c])
            {
              arr[e] = buf[c]; e--; c--;
            }
            arr[e] = arr[d]; e--; d--;
          }
          while (c >= s)
          {
            arr[e] = buf[c]; e--; c--;
          }
        }
        offset += block * 2;
      }
      block *= 2;
    }
  }

  private static void Twinsort(int[] arr, int nmemb)
  {
    if (TwinSwap(arr, nmemb) == 0)
    {
      int[] buf = new int[nmemb / 2];
      TailMerge(arr, buf, nmemb, 2);
    }
  }

  public static void Sort(int[] arr)
  {
    int n = arr.Length;
    Twinsort(arr, n);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
