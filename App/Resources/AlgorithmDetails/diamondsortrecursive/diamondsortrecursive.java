import java.util.Arrays;

public class diamondsortrecursive {
  public static void sort(int[] arr) {
    if (arr.length < 2) {
      return;
    }
    int paddedLength = 1;
    while (paddedLength < arr.length) {
      paddedLength *= 2;
    }
    sort(arr, 0, paddedLength, true);
  }

  // [start, stop) is the half-open range being sorted. merge selects whether
  // the two halves are recursively pre-sorted before the fixed diamond
  // comparison pattern below merges them together.
  private static void sort(int[] arr, int start, int stop, boolean merge) {
    if (stop - start == 2) {
      if (stop <= arr.length && arr[start] > arr[stop - 1]) {
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
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56
    };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
