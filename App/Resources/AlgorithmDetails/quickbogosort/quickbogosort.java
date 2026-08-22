import java.util.Arrays;

public class quickbogosort {
  public static boolean isPartitioned(int[] arr, int start, int pivot, int end) {
    for (int i = start; i < pivot; i++) {
      if (arr[i] > arr[pivot]) {
        return false;
      }
    }
    for (int i = pivot + 1; i < end; i++) {
      if (arr[pivot] > arr[i]) {
        return false;
      }
    }
    return true;
  }

  public static void sort(int[] arr, int start, int end) {
    if (start >= end - 1) {
      return;
    }

    int pivot = start;

    while (!isPartitioned(arr, start, pivot, end)) {
      for (int i = start; i < end; i++) {
        int j = i + (int) (Math.random() * (end - i));
        if (pivot == i) {
          pivot = j;
        } else if (pivot == j) {
          pivot = i;
        }
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
      }
    }

    sort(arr, start, pivot);
    sort(arr, pivot + 1, end);
  }

  public static void sort(int[] arr) {
    sort(arr, 0, arr.length);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 14, 23};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
