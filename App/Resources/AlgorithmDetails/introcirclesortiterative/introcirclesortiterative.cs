using System;

public class IntroCircleSortIterative {
  public static int CircleSortRoutine(int[] array, int length, int end) {
    var swapCount = 0;
    for (var gap = length / 2; gap > 0; gap /= 2) {
      for (var start = 0; start + gap < end; start += 2 * gap) {
        var low = start;
        var high = start + 2 * gap - 1;
        while (low < high) {
          if (high < end && array[low] > array[high]) {
            (array[low], array[high]) = (array[high], array[low]);
            swapCount++;
          }
          low++;
          high--;
        }
      }
    }
    return swapCount;
  }

  public static void BinaryInsertionSort(int[] array, int end) {
    for (var i = 1; i < end; i++) {
      var value = array[i];
      var lo = 0;
      var hi = i;
      while (lo < hi) {
        var mid = lo + (hi - lo) / 2;
        if (value < array[mid]) {
          hi = mid;
        } else {
          lo = mid + 1;
        }
      }
      var j = i;
      while (j > lo) {
        array[j] = array[j - 1];
        j--;
      }
      array[lo] = value;
    }
  }

  public static int[] Sort(int[] array) {
    var end = array.Length;
    if (end <= 1) return array;
    var n = 1;
    var threshold = 0;
    while (n < end) {
      n <<= 1;
      threshold++;
    }
    threshold /= 2;

    var iterations = 0;
    while (true) {
      iterations++;
      if (iterations >= threshold) {
        BinaryInsertionSort(array, end);
        return array;
      }
      if (CircleSortRoutine(array, n, end) == 0) {
        return array;
      }
    }
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
