import java.util.Arrays;

public class introsort {
  private static final int SIZE_THRESHOLD = 16;

  private static void swap(int[] arr, int a, int b) {
    int t = arr[a];
    arr[a] = arr[b];
    arr[b] = t;
  }

  private static int medianOf3(int[] arr, int left, int mid, int right) {
    if (!(arr[left] >= arr[right])) {
      swap(arr, left, right);
    }
    if (!(arr[left] >= arr[mid])) {
      swap(arr, left, mid);
    }
    if (!(arr[mid] >= arr[right])) {
      swap(arr, mid, right);
    }
    return mid;
  }

  private static int partition(int[] arr, int lo, int hi, int pivotValue) {
    int i = lo;
    int j = hi;
    while (true) {
      while (arr[i] < pivotValue) {
        i++;
      }
      j--;
      while (pivotValue < arr[j]) {
        j--;
      }
      if (!(i < j)) {
        return i;
      }
      swap(arr, i, j);
      i++;
    }
  }

  private static void siftDown(int[] arr, int lo, int root, int rangeSize) {
    while (true) {
      int largest = root;
      int left = 2 * root + 1;
      int right = 2 * root + 2;
      if (left < rangeSize && arr[lo + largest] < arr[lo + left]) {
        largest = left;
      }
      if (right < rangeSize && arr[lo + largest] < arr[lo + right]) {
        largest = right;
      }
      if (largest == root) {
        break;
      }
      swap(arr, lo + root, lo + largest);
      root = largest;
    }
  }

  private static void heapSortRange(int[] arr, int lo, int hi) {
    int size = hi - lo;
    for (int i = size / 2 - 1; i >= 0; i--) {
      siftDown(arr, lo, i, size);
    }
    for (int end = size - 1; end > 0; end--) {
      swap(arr, lo, lo + end);
      siftDown(arr, lo, 0, end);
    }
  }

  private static void insertionSort(int[] arr, int start, int end) {
    for (int i = start + 1; i < end; i++) {
      int j = i;
      while (j > start && arr[j] < arr[j - 1]) {
        swap(arr, j - 1, j);
        j--;
      }
    }
  }

  private static int floorLog2(int a) {
    return (int) Math.floor(Math.log(a) / Math.log(2));
  }

  private static void introsortLoop(int[] arr, int lo, int hi, int depthLimit) {
    while (hi - lo > SIZE_THRESHOLD) {
      if (depthLimit == 0) {
        heapSortRange(arr, lo, hi);
        return;
      }
      depthLimit--;
      int mid = lo + (hi - lo) / 2;
      int pivotIndex = medianOf3(arr, lo, mid, hi - 1);
      int pivotValue = arr[pivotIndex];
      int p = partition(arr, lo, hi, pivotValue);
      introsortLoop(arr, p, hi, depthLimit);
      hi = p;
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    introsortLoop(arr, 0, n, 2 * floorLog2(n));
    insertionSort(arr, 0, n);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
