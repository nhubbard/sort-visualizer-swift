import java.util.Arrays;

public class binarygnomesort {
  private static int binarySearch(int[] arr, int item, int start, int end) {
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

  public static void sort(int[] arr) {
    for (int i = 1; i < arr.length; i++) {
      int item = arr[i];
      int pos = binarySearch(arr, item, 0, i);
      int j = i;
      while (j > pos) {
        int temp = arr[j];
        arr[j] = arr[j - 1];
        arr[j - 1] = temp;
        j--;
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
