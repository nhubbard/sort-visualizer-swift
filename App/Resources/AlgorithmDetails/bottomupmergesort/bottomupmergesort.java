import java.util.Arrays;

public class bottomupmergesort {
  public static void sort(int[] arr) {
    int n = arr.length;
    if (n < 2) return;
    int[] scratch = arr.clone();
    int mergeSize = 2;
    while (mergeSize <= n) {
      int copyLength = n;
      for (int index = 0; index < n; index += mergeSize) {
        int stop = merge(arr, scratch, n, index, mergeSize);
        if (stop >= 0) copyLength = stop;
      }
      System.arraycopy(scratch, 0, arr, 0, copyLength);
      mergeSize *= 2;
    }
    if (mergeSize / 2 != n) {
      int stop = merge(arr, scratch, n, 0, mergeSize);
      System.arraycopy(scratch, 0, arr, 0, stop < 0 ? n : stop);
    }
  }

  private static int merge(int[] arr, int[] scratch, int n, int index, int mergeSize) {
    int mid = index + mergeSize / 2;
    int end = Math.min(n, index + mergeSize);
    if (mid >= end) return index;
    int left = index, right = mid, out = index;
    while (left < mid && right < end)
      scratch[out++] = arr[left] <= arr[right] ? arr[left++] : arr[right++];
    while (left < mid) scratch[out++] = arr[left++];
    while (right < end) scratch[out++] = arr[right++];
    return -1;
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
