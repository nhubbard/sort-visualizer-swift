import java.util.Arrays;

public class binaryinsertionsort {
  private static int binarySearch(int arr[], int item, int start, int end) {
    int low = start;
    int high = end;
    while (low < high) {
      int mid = low + (high - low) / 2;
      if (item < arr[mid]) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    return low;
  }

  public static void sort(int arr[]) {
    for (int i = 1; i < arr.length; i++) {
      int item = arr[i];
      int pos = binarySearch(arr, item, 0, i);
      int j = i;
      while (j > pos) {
        arr[j] = arr[j - 1];
        j--;
      }
      arr[pos] = item;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
