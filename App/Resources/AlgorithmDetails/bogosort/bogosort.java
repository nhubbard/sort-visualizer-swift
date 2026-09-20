import java.util.Arrays;

public class bogosort {
  private static void reverse(int[] a, int low, int high) {
    while (low < high) {
      int held = a[low];
      a[low] = a[high];
      a[high] = held;
      low++;
      high--;
    }
  }

  public static void sort(int[] a) {
    int n = a.length;
    if (n < 2) return;
    boolean ordered = true;
    for (int i = 1; i < n; i++)
      if (a[i] < a[i - 1]) {
        ordered = false;
        break;
      }
    if (ordered) return;
    while (true) {
      int pivot = n - 2;
      while (pivot >= 0 && a[pivot] >= a[pivot + 1]) pivot--;
      if (pivot < 0) break;
      int successor = n - 1;
      while (a[successor] <= a[pivot]) successor--;
      int held = a[pivot];
      a[pivot] = a[successor];
      a[successor] = held;
      reverse(a, pivot + 1, n - 1);
    }
    reverse(a, 0, n - 1);
  }

  public static void main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
