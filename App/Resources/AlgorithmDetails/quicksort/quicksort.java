import java.util.Arrays;

public class quicksort {
  public static void sort(int[] arr) {
    quickSort(arr, 0, arr.length - 1);
  }

  private static int partition(int[] arr, int left, int right) {
    int i = left;
    int j = right;
    while (i < j) {
      while (i < j && arr[i] <= arr[left]) i++;
      while (arr[j] > arr[left]) j--;
      if (i < j) {
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
      }
    }
    int temp = arr[left];
    arr[left] = arr[j];
    arr[j] = temp;
    return j;
  }

  public static void quickSort(int[] arr, int begin, int end) {
    if (begin < end) {
      int partitionIndex = partition(arr, begin, end);
      quickSort(arr, begin, partitionIndex - 1);
      quickSort(arr, partitionIndex + 1, end);
    }
  }

  public static void main(String[] args) {
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56
    };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
