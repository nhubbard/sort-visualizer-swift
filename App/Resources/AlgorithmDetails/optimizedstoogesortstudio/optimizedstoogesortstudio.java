import java.util.Arrays;

public class optimizedstoogesortstudio {
  private static boolean compSwap(int[] arr, int a, int b) {
    if (arr[a] > arr[b]) {
      int temp = arr[a];
      arr[a] = arr[b];
      arr[b] = temp;
      return true;
    }
    return false;
  }

  private static boolean stoogeSort(int[] arr, int a, int m, int b, boolean merge) {
    if (a >= m) return false;
    if (b - a == 2) return compSwap(arr, a, m);

    boolean lChange = false;
    boolean rChange = false;

    int a2 = (a + a + b) / 3;
    int b2 = (a + b + b + 2) / 3;

    if (m < b2) {
      lChange = stoogeSort(arr, a, m, b2, merge);
      if (merge) {
        rChange = stoogeSort(arr, Math.max(a + b2 - m, a2), b2, b, true);
        if (rChange) {
          stoogeSort(arr, a + b2 - m, a2, 2 * a2 - a, true);
        }
      } else {
        rChange = stoogeSort(arr, a2, b2, b, false);
        if (rChange) {
          stoogeSort(arr, a, a2, 2 * a2 - a, true);
        }
      }
    } else {
      rChange = stoogeSort(arr, a2, m, b, merge);
      if (rChange) {
        stoogeSort(arr, a, a2, a2 + b - m, true);
      }
    }

    return lChange || rChange;
  }

  public static void sort(int[] arr) {
    stoogeSort(arr, 0, 1, arr.length, false);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
