import java.util.Arrays;

public class quicksort {
  public static void quickSort(int arr[], int begin, int end) {
    if (begin < end) {
      int partitionIndex = partition(arr, begin, end);
      quickSort(arr, begin, partitionIndex - 1);
      quickSort(arr, partitionIndex + 1, end);
    }
  }

  private static int partition(int arr[], int begin, int end) {
    int pivot = arr[end];
    int i = begin - 1;
    for (int j = begin; j < end; j++) {
      if (arr[j] <= pivot) {
        i++;
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
      }
    }
    int temp = arr[i + 1];
    arr[i + 1] = arr[end];
    arr[end] = temp;
    return i + 1;
  }

  public static void main(String[] args) {
    int[] items = new int[]{35, 95, 74, 71, 72, 30, 96, 53, 9, 0};
    quickSort(items, 0, items.length - 1);
    System.out.println(Arrays.toString(items));
  }
}
