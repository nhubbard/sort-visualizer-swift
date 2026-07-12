using System;

public class CircleSortRecursive {
  public static int NextPowerOfTwo(int n) {
    var k = 1;
    while (k < n) {
      k <<= 1;
    }
    return k;
  }

  public static int CircleSortRoutine(int[] array, int lo, int hi, int end) {
    if (lo == hi) {
      return 0;
    }
    var low = lo;
    var high = hi;
    var mid = (hi - lo) / 2;
    var swaps = 0;
    while (lo < hi) {
      if (hi < end && array[lo] > array[hi]) {
        (array[lo], array[hi]) = (array[hi], array[lo]);
        swaps++;
      }
      lo++;
      hi--;
    }
    swaps += CircleSortRoutine(array, low, low + mid, end);
    if (low + mid + 1 < end) {
      swaps += CircleSortRoutine(array, low + mid + 1, high, end);
    }
    return swaps;
  }

  public static int[] Sort(int[] array) {
    var end = array.Length;
    if (end == 0) {
      return array;
    }
    var paddedLength = NextPowerOfTwo(end);
    int swaps;
    do {
      swaps = CircleSortRoutine(array, 0, paddedLength - 1, end);
    } while (swaps != 0);
    return array;
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
