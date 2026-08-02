import java.util.Arrays;

public class creasesort {
  private static void compSwap(int[] arr, int a, int b) {
    if (arr[a] > arr[b]) {
      int temp = arr[a];
      arr[a] = arr[b];
      arr[b] = temp;
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    int maxVal = 1;
    while (maxVal * 2 < n) {
      maxVal *= 2;
    }

    int next = maxVal;
    while (next > 0) {
      int i = 0;
      while (i + 1 < n) {
        compSwap(arr, i, i + 1);
        i += 2;
      }

      int j = maxVal;
      while (j >= next && j > 1) {
        i = 1;
        while (i + j - 1 < n) {
          compSwap(arr, i, i + j - 1);
          i += 2;
        }
        j /= 2;
      }

      next /= 2;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
