import java.util.Arrays;

public class cocktailbogosort {
  public static boolean isMinimum(int[] arr, int start, int end) {
    for (int k = start + 1; k < end; k++) {
      if (arr[start] > arr[k]) {
        return false;
      }
    }
    return true;
  }

  public static boolean isMaximum(int[] arr, int start, int end) {
    for (int k = start; k < end - 1; k++) {
      if (arr[k] > arr[end - 1]) {
        return false;
      }
    }
    return true;
  }

  public static void shuffleRange(int[] arr, int start, int end) {
    for (int i = start; i < end - 1; i++) {
      int j = i + (int) (Math.random() * (end - i));
      int t = arr[i];
      arr[i] = arr[j];
      arr[j] = t;
    }
  }

  public static void sort(int[] arr) {
    int lo = 0;
    int hi = arr.length;
    while (lo < hi - 1) {
      if (isMinimum(arr, lo, hi)) {
        lo++;
      } else if (isMaximum(arr, lo, hi)) {
        hi--;
      } else {
        shuffleRange(arr, lo, hi);
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
