using System;

public class MinHeapSort {
  private static void SiftDown(int[] arr, int root, int size) {
    while (true) {
      var smallest = root;
      var left = 2 * root + 1;
      var right = 2 * root + 2;
      if (left < size && arr[left] < arr[smallest]) {
        smallest = left;
      }
      if (right < size && arr[right] < arr[smallest]) {
        smallest = right;
      }
      if (smallest == root) {
        break;
      }
      (arr[root], arr[smallest]) = (arr[smallest], arr[root]);
      root = smallest;
    }
  }

  private static void Heapify(int[] arr) {
    for (var i = arr.Length / 2 - 1; i >= 0; i--) {
      SiftDown(arr, i, arr.Length);
    }
  }

  public static int[] Sort(int[] array) {
    Heapify(array);
    for (var end = array.Length - 1; end > 0; end--) {
      (array[0], array[end]) = (array[end], array[0]);
      SiftDown(array, 0, end);
    }
    Array.Reverse(array);
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
