import java.util.Arrays;

public class mergeexchangesortiterative {
  private static void mergeExchangeSort(int[] arr) {
    int n = arr.length;
    if (n <= 1) {
      return;
    }
    int t = (int) (Math.log(n - 1) / Math.log(2)) + 1;
    int p0 = 1 << (t - 1);
    for (int p = p0; p > 0; p >>= 1) {
      int q = p0;
      int r = 0;
      int d = p;
      while (true) {
        for (int i = 0; i < n - d; i++) {
          if ((i & p) == r && arr[i] > arr[i + d]) {
            int temp = arr[i];
            arr[i] = arr[i + d];
            arr[i + d] = temp;
          }
        }
        if (q == p) {
          break;
        }
        d = q - p;
        q >>= 1;
        r = p;
      }
    }
  }

  public static void sort(int[] arr) {
    mergeExchangeSort(arr);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
