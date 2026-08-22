import java.util.Arrays;

public class weavesortrecursive {
  private static int end;

  private static void compSwap(int[] arr, int a, int b) {
    if (b < end && arr[a] > arr[b]) {
      int temp = arr[a];
      arr[a] = arr[b];
      arr[b] = temp;
    }
  }

  private static void circle(int[] arr, int pos, int ln, int gap) {
    if (ln < 2) {
      return;
    }
    int i = 0;
    while (2 * i < (ln - 1) * gap) {
      compSwap(arr, pos + i, pos + (ln - 1) * gap - i);
      i += gap;
    }
    circle(arr, pos, ln / 2, gap);
    if (pos + ln * gap / 2 < end) {
      circle(arr, pos + ln * gap / 2, ln / 2, gap);
    }
  }

  private static void weaveCircle(int[] arr, int pos, int ln, int gap) {
    if (ln < 2) {
      return;
    }
    weaveCircle(arr, pos, ln / 2, 2 * gap);
    weaveCircle(arr, pos + gap, ln / 2, 2 * gap);
    circle(arr, pos, ln, gap);
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    end = n;
    int padded = 1;
    while (padded < end) {
      padded *= 2;
    }
    weaveCircle(arr, 0, padded, 1);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
