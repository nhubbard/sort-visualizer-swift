import java.util.Arrays;

public class threesmoothcombsortrecursive {
  private static void powerOfThree(int[] arr, int pos, int gap, int end) {
    if (pos + gap > end) {
      return;
    }

    powerOfThree(arr, pos, gap * 3, end);
    powerOfThree(arr, pos + gap, gap * 3, end);
    powerOfThree(arr, pos + 2 * gap, gap * 3, end);

    for (int i = pos; i + gap < end; i += gap) {
      if (arr[i] > arr[i + gap]) {
        int t = arr[i];
        arr[i] = arr[i + gap];
        arr[i + gap] = t;
      }
    }
  }

  private static void recursiveComb(int[] arr, int pos, int gap, int end) {
    if (pos + gap > end) {
      return;
    }

    recursiveComb(arr, pos, gap * 2, end);
    recursiveComb(arr, pos + gap, gap * 2, end);

    powerOfThree(arr, pos, gap, end);
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n > 1) {
      recursiveComb(arr, 0, 1, n);
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
