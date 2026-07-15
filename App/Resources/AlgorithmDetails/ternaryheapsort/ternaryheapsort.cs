using System;

public class TernaryHeapSort {
  public static void MaxHeapify(int[] arr, int i, int heapSize) {
    int left = 3 * i + 1;
    int mid = 3 * i + 2;
    int right = 3 * i + 3;
    int largest = i;
    if (left <= heapSize && arr[left] > arr[largest]) { largest = left; }
    if (right <= heapSize && arr[right] > arr[largest]) { largest = right; }
    if (mid <= heapSize && arr[mid] > arr[largest]) { largest = mid; }
    if (largest != i) {
      (arr[i], arr[largest]) = (arr[largest], arr[i]);
      MaxHeapify(arr, largest, heapSize);
    }
  }

  public static void Sort(int[] arr) {
    int n = arr.Length;
    int heapSize = n - 1;
    for (int i = n - 1; i >= 0; i--) { MaxHeapify(arr, i, heapSize); }
    for (int i = n - 1; i >= 0; i--) {
      (arr[0], arr[i]) = (arr[i], arr[0]);
      heapSize -= 1;
      MaxHeapify(arr, 0, heapSize);
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
