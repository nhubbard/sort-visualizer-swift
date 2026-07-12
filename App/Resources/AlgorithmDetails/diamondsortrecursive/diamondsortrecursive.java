import java.util.Arrays;

public class diamondsortrecursive {
  // [start, stop) is the half-open range being sorted. merge selects whether
  // the two halves are recursively pre-sorted before the fixed diamond
  // comparison pattern below merges them together.
  private static void sort(int[] arr, int start, int stop, boolean merge) {
    if (stop - start == 2) {
      if (arr[start] > arr[stop - 1]) {
        int temp = arr[start];
        arr[start] = arr[stop - 1];
        arr[stop - 1] = temp;
      }
    } else if (stop - start >= 3) {
      double div = (stop - start) / 4.0;
      int mid = (stop - start) / 2 + start;
      int quarter = (int) div + start;
      int threeQuarters = (int) (div * 3) + start;

      if (merge) {
        sort(arr, start, mid, true);
        sort(arr, mid, stop, true);
      }
      sort(arr, quarter, threeQuarters, false);
      sort(arr, start, mid, false);
      sort(arr, mid, stop, false);
      sort(arr, quarter, threeQuarters, false);
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array, 0, array.length, true);
    System.out.println(Arrays.toString(array));
  }
}
