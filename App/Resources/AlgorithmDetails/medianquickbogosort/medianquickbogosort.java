import java.util.Arrays;

public class medianquickbogosort {
  public static boolean isSplit(int[] arr, int start, int mid, int end) {
    int lowMax = arr[start];
    for (int i = start + 1; i < mid; i++) {
      if (arr[i] > lowMax) {
        lowMax = arr[i];
      }
    }
    for (int i = mid; i < end; i++) {
      if (lowMax > arr[i]) {
        return false;
      }
    }
    return true;
  }

  public static void sort(int[] arr, int start, int end) {
    if (start >= end - 1) {
      return;
    }
    int mid = (start + end) / 2;

    while (!isSplit(arr, start, mid, end)) {
      for (int i = end - 1; i > start; i--) {
        int j = start + (int) (Math.random() * (i - start + 1));
        int tmp = arr[i];
        arr[i] = arr[j];
        arr[j] = tmp;
      }
    }

    sort(arr, start, mid);
    sort(arr, mid, end);
  }

  public static void sort(int[] arr) {
    sort(arr, 0, arr.length);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 14, 23};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
