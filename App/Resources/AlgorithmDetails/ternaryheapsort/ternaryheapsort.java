import java.util.Arrays;

public class ternaryheapsort {
  public static void maxHeapify(int[] arr, int i, int heapSize) {
    int left = 3 * i + 1;
    int mid = 3 * i + 2;
    int right = 3 * i + 3;
    int largest = i;
    if (left <= heapSize && arr[left] > arr[largest]) {
      largest = left;
    }
    if (right <= heapSize && arr[right] > arr[largest]) {
      largest = right;
    }
    if (mid <= heapSize && arr[mid] > arr[largest]) {
      largest = mid;
    }
    if (largest != i) {
      int temp = arr[i];
      arr[i] = arr[largest];
      arr[largest] = temp;
      maxHeapify(arr, largest, heapSize);
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    int heapSize = n - 1;
    for (int i = n - 1; i >= 0; i--) {
      maxHeapify(arr, i, heapSize);
    }
    for (int i = n - 1; i >= 0; i--) {
      int temp = arr[0];
      arr[0] = arr[i];
      arr[i] = temp;
      heapSize -= 1;
      maxHeapify(arr, 0, heapSize);
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
