import java.util.Arrays;

public class snufflesort {
  private static void snuffleSort(int[] arr, int start, int stop) {
    if (stop - start + 1 >= 2) {
      if (arr[start] > arr[stop]) {
        int temp = arr[start];
        arr[start] = arr[stop];
        arr[stop] = temp;
      }
      if (stop - start + 1 >= 3) {
        int mid = (stop - start) / 2 + start;
        int iterations = (stop - start + 1) / 2;
        for (int i = 0; i < iterations; i++) {
          snuffleSort(arr, start, mid);
          snuffleSort(arr, mid, stop);
        }
      }
    }
  }

  public static void sort(int[] arr) {
    snuffleSort(arr, 0, arr.length - 1);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
