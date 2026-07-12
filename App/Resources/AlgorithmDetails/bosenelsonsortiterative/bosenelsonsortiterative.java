import java.util.Arrays;

public class bosenelsonsortiterative {
  private static int end;

  private static void compSwap(int[] arr, int a, int b) {
    if (b >= end) return;
    if (arr[a] > arr[b]) {
      int temp = arr[a];
      arr[a] = arr[b];
      arr[b] = temp;
    }
  }

  private static void rangeComp(int[] arr, int a, int b, int offset) {
    int half = (b - a) / 2;
    int m = a + half;
    int base = a + offset;
    for (int i = 0; i < half - offset; i++) {
      if ((i & ~offset) == i) {
        compSwap(arr, base + i, m + i);
      }
    }
  }

  public static void sort(int[] arr) {
    end = arr.length;
    if (end <= 1) return;
    int paddedLength = 1;
    while (paddedLength < end) paddedLength <<= 1;

    for (int k = 2; k <= paddedLength; k *= 2) {
      for (int j = 0; j < k / 2; j++) {
        for (int i = 0; i + j < end; i += k) {
          rangeComp(arr, i, i + k, j);
        }
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
