import java.util.Arrays;

public class pairwisesortrecursive {
  private static void compSwap(int[] arr, int a, int b) {
    if (arr[a] > arr[b]) {
      int temp = arr[a];
      arr[a] = arr[b];
      arr[b] = temp;
    }
  }

  private static void pairwiseRecursive(int[] arr, int start, int end, int gap) {
    if (start == end - gap) {
      return;
    }
    int b = start + gap;
    while (b < end) {
      compSwap(arr, b - gap, b);
      b += 2 * gap;
    }

    if (((end - start) / gap) % 2 == 0) {
      pairwiseRecursive(arr, start, end, gap * 2);
      pairwiseRecursive(arr, start + gap, end + gap, gap * 2);
    } else {
      pairwiseRecursive(arr, start, end + gap, gap * 2);
      pairwiseRecursive(arr, start + gap, end, gap * 2);
    }

    int a = 1;
    while (a < (end - start) / gap) {
      a = (a * 2) + 1;
    }

    b = start + gap;
    while (b + gap < end) {
      int c = a;
      while (c > 1) {
        c /= 2;
        if (b + (c * gap) < end) {
          compSwap(arr, b, b + (c * gap));
        }
      }
      b += 2 * gap;
    }
  }

  public static void sort(int[] arr) {
    pairwiseRecursive(arr, 0, arr.length, 1);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
