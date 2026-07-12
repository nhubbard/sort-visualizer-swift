using System;

public class Introsort {
  private const int SizeThreshold = 16;

  private static void Swap(int[] arr, int a, int b) {
    (arr[a], arr[b]) = (arr[b], arr[a]);
  }

  private static int MedianOf3(int[] arr, int left, int mid, int right) {
    if (!(arr[left] >= arr[right])) {
      Swap(arr, left, right);
    }
    if (!(arr[left] >= arr[mid])) {
      Swap(arr, left, mid);
    }
    if (!(arr[mid] >= arr[right])) {
      Swap(arr, mid, right);
    }
    return mid;
  }

  private static int Partition(int[] arr, int lo, int hi, int pivotValue) {
    int i = lo, j = hi;
    while (true) {
      while (arr[i] < pivotValue) i++;
      j--;
      while (pivotValue < arr[j]) j--;
      if (!(i < j)) return i;
      Swap(arr, i, j);
      i++;
    }
  }

  private static void SiftDown(int[] arr, int lo, int root, int rangeSize) {
    while (true) {
      int largest = root;
      int left = 2 * root + 1;
      int right = 2 * root + 2;
      if (left < rangeSize && arr[lo + largest] < arr[lo + left]) largest = left;
      if (right < rangeSize && arr[lo + largest] < arr[lo + right]) largest = right;
      if (largest == root) break;
      Swap(arr, lo + root, lo + largest);
      root = largest;
    }
  }

  private static void HeapSortRange(int[] arr, int lo, int hi) {
    int size = hi - lo;
    for (int i = size / 2 - 1; i >= 0; i--) SiftDown(arr, lo, i, size);
    for (int end = size - 1; end > 0; end--) {
      Swap(arr, lo, lo + end);
      SiftDown(arr, lo, 0, end);
    }
  }

  private static void InsertionSort(int[] arr, int start, int end) {
    for (int i = start + 1; i < end; i++) {
      int j = i;
      while (j > start && arr[j] < arr[j - 1]) {
        Swap(arr, j - 1, j);
        j--;
      }
    }
  }

  private static int FloorLog2(int a) {
    return (int)Math.Floor(Math.Log(a) / Math.Log(2));
  }

  private static void IntrosortLoop(int[] arr, int lo, int hi, int depthLimit) {
    while (hi - lo > SizeThreshold) {
      if (depthLimit == 0) {
        HeapSortRange(arr, lo, hi);
        return;
      }
      depthLimit--;
      int mid = lo + (hi - lo) / 2;
      int pivotIndex = MedianOf3(arr, lo, mid, hi - 1);
      int pivotValue = arr[pivotIndex];
      int p = Partition(arr, lo, hi, pivotValue);
      IntrosortLoop(arr, p, hi, depthLimit);
      hi = p;
    }
  }

  public static void Sort(int[] arr) {
    int n = arr.Length;
    IntrosortLoop(arr, 0, n, 2 * FloorLog2(n));
    InsertionSort(arr, 0, n);
  }

  public static void Main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    Sort(array);
    string result = "[" + String.Join(", ", array) + "]";
    Console.WriteLine(result);
  }
}
