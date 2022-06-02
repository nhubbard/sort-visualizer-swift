using System;

public class HeapSort {
  public static void Heapify(int[] arr, int n, int i) {
    int largest = i;
    int l = 2 * i + 1;
    int r = 2 * i + 2;
    if (l < n && arr[l] > arr[largest]) {
      largest = l;
    }
    if (r < n && arr[r] > arr[largest]) {
      largest = r;
    }
    if (largest != i) {
      (arr[i], arr[largest]) = (arr[largest], arr[i]);
      Heapify(arr, n, largest);
    }
  }

  public static void Sort(int[] arr) {
    int n = arr.Length;
    for (int i = n / 2 - 1; i >= 0; i--) {
      Heapify(arr, n, i);
    }
    for (int i = n - 1; i >= 0; i--) {
      (arr[0], arr[i]) = (arr[i], arr[0]);
      Heapify(arr, i, 0);
    }
  }

  public static void Main(String[] args) {
      int[] array = {1, 5, 2, 3, 7, 4, 8, 9};
      Sort(array);
      string result = "[" + String.Join(", ", array) + "]";
      Console.WriteLine(result);
  }
}