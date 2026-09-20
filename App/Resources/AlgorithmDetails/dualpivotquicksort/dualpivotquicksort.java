import java.util.Arrays;

public class dualpivotquicksort {
  private static void swap(int[] a, int i, int j) {
    int t = a[i]; a[i] = a[j]; a[j] = t;
  }

  private static void insertionSort(int[] a, int start, int end) {
    for (int i = start + 1; i < end; i++) {
      for (int j = i; j > start && a[j] < a[j - 1]; j--) swap(a, j - 1, j);
    }
  }

  private static void dualPivotQuickSort(int[] a, int left, int right, int divisor) {
    int length = right - left;
    if (length < 4) { insertionSort(a, left, right + 1); return; }
    int third = length / divisor;
    int med1 = left + third, med2 = right - third;
    if (med1 <= left) med1 = left + 1;
    if (med2 >= right) med2 = right - 1;
    if (a[med1] < a[med2]) { swap(a, med1, left); swap(a, med2, right); }
    else { swap(a, med1, right); swap(a, med2, left); }
    int pivot1 = a[left], pivot2 = a[right];
    int less = left + 1, great = right - 1;
    for (int k = less; k <= great; k++) {
      if (a[k] < pivot1) { swap(a, k, less); less++; }
      else if (a[k] > pivot2) {
        while (k < great && a[great] > pivot2) great--;
        swap(a, k, great); great--;
        if (a[k] < pivot1) { swap(a, k, less); less++; }
      }
    }
    if (great - less < 13) divisor++;
    swap(a, less - 1, left); swap(a, great + 1, right);
    dualPivotQuickSort(a, left, less - 2, divisor);
    if (pivot1 < pivot2) dualPivotQuickSort(a, less, great, divisor);
    dualPivotQuickSort(a, great + 2, right, divisor);
  }

  public static void sort(int[] arr) {
    dualPivotQuickSort(arr, 0, arr.length - 1, 3);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
