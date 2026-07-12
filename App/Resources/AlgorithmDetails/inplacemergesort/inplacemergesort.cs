using System;

public class InPlaceMergeSort {
  private static void Push(int[] array, int low, int high) {
    for (var i = low; i < high; i++) {
      if (array[i] > array[i + 1]) {
        (array[i], array[i + 1]) = (array[i + 1], array[i]);
      }
    }
  }

  private static void Merge(int[] array, int low, int high, int mid) {
    var i = low;
    while (i <= mid) {
      if (array[i] > array[mid + 1]) {
        (array[i], array[mid + 1]) = (array[mid + 1], array[i]);
        Push(array, mid + 1, high);
      }
      i++;
    }
  }

  private static void MergeSort(int[] array, int low, int high) {
    if (high - low == 0) {
      return;
    } else if (high - low == 1) {
      if (array[low] > array[high]) {
        (array[low], array[high]) = (array[high], array[low]);
      }
    } else {
      var mid = (low + high) / 2;
      MergeSort(array, low, mid);
      MergeSort(array, mid + 1, high);
      Merge(array, low, high, mid);
    }
  }

  public static int[] Sort(int[] array) {
    if (array.Length >= 2) {
      MergeSort(array, 0, array.Length - 1);
    }
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
