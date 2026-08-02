using System;

public class BufferedStoogeSort
{
  private static void Sort(int[] arr, int start, int stop)
  {
    if (stop - start > 1)
    {
      if (stop - start == 2 && arr[start] > arr[stop - 1])
      {
        (arr[start], arr[stop - 1]) = (arr[stop - 1], arr[start]);
      }
      if (stop - start > 2)
      {
        int width = stop - start;
        int third = (width + 2) / 3 + start;
        int twoThird = (2 * width + 2) / 3 + start;
        if (twoThird - third < third)
        {
          twoThird--;
        }
        if ((width - 2) % 3 == 0)
        {
          twoThird--;
        }

        Sort(arr, third, twoThird);
        Sort(arr, twoThird, stop);

        int left = third;
        int right = twoThird;
        int bufferStart = start;
        while (left < twoThird && right < stop)
        {
          if (arr[left] > arr[right])
          {
            (arr[bufferStart], arr[right]) = (arr[right], arr[bufferStart]);
            right++;
          }
          else
          {
            (arr[bufferStart], arr[left]) = (arr[left], arr[bufferStart]);
            left++;
          }
          bufferStart++;
        }
        while (right < stop)
        {
          (arr[bufferStart], arr[right]) = (arr[right], arr[bufferStart]);
          right++;
          bufferStart++;
        }

        Sort(arr, twoThird, stop);

        left = twoThird - 1;
        right = stop - 1;
        while (right > left && left >= start)
        {
          if (arr[left] > arr[right])
          {
            for (int i = left; i < right; i++)
            {
              (arr[i], arr[i + 1]) = (arr[i + 1], arr[i]);
            }
            left--;
          }
          right--;
        }
      }
    }
  }

  public static void Sort(int[] arr)
  {
    Sort(arr, 0, arr.Length);
  }

  public static void Main(String[] args)
  {
    int[] array = { 0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56 };
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}