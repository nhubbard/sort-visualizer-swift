import java.util.Arrays;

public class timesort {
  private static void mergeSort(int[] scratch, int[] buffer, int lo, int hi) {
    if (hi - lo < 2) return;
    int mid = lo + (hi - lo) / 2;
    mergeSort(scratch, buffer, lo, mid);
    mergeSort(scratch, buffer, mid, hi);
    int left = lo, right = mid, dest = lo;
    while (left < mid && right < hi) {
      if (scratch[left] <= scratch[right]) buffer[dest++] = scratch[left++];
      else buffer[dest++] = scratch[right++];
    }
    while (left < mid) buffer[dest++] = scratch[left++];
    while (right < hi) buffer[dest++] = scratch[right++];
    System.arraycopy(buffer, lo, scratch, lo, hi - lo);
  }

  public static void sort(int[] a) {
    int n = a.length;
    if (n < 2) return;
    int[] scratch = a.clone();
    int[] buffer = scratch.clone();
    mergeSort(scratch, buffer, 0, n);
    System.arraycopy(scratch, 0, a, 0, n);
    for (int i = 1; i < n; i++) {
      int j = i;
      while (j > 0 && a[j - 1] > a[j]) {
        int held = a[j - 1];
        a[j - 1] = a[j];
        a[j] = held;
        j--;
      }
    }
  }

  public static void main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
