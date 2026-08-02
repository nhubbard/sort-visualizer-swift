import java.util.Arrays;

public class binarymergesort {
  private static final int THRESHOLD = 32;

  public static void insertionSort(int[] arr, int start, int end) {
    for (int i = start + 1; i < end; i++) {
      int j = i;
      while (j > start && arr[j] < arr[j - 1]) {
        int temp = arr[j - 1];
        arr[j - 1] = arr[j];
        arr[j] = temp;
        j--;
      }
    }
  }

  public static void merge(int[] arr, int start, int mid, int end) {
    int low = start;
    int high = mid;
    int[] merged = new int[end - start];
    int k = 0;
    while (low < mid && high < end) {
      if (arr[high] < arr[low]) {
        merged[k++] = arr[high++];
      } else {
        merged[k++] = arr[low++];
      }
    }
    while (low < mid) {
      merged[k++] = arr[low++];
    }
    while (high < end) {
      merged[k++] = arr[high++];
    }
    for (int i = 0; i < k; i++) {
      arr[start + i] = merged[i];
    }
  }

  public static void mergeSort(int[] arr, int start, int end) {
    if (end - start <= THRESHOLD) {
      insertionSort(arr, start, end);
      return;
    }
    int mid = start + (end - start) / 2;
    mergeSort(arr, start, mid);
    mergeSort(arr, mid, end);
    merge(arr, start, mid, end);
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n < 2) {
      return;
    }
    mergeSort(arr, 0, n);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
