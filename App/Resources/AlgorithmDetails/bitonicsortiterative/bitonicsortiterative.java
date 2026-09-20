import java.util.Arrays;

public class bitonicsortiterative {
  public static void sort(int[] arr) {
    int n = arr.length;
    for (int k = 2; k < 2 * n; k *= 2) {
      boolean m = ((n + k - 1) / k) % 2 != 0;
      for (int j = k / 2; j > 0; j /= 2) {
        for (int i = 0; i < n; i++) {
          int l = i ^ j;
          if (l > i && l < n) {
            boolean ascending = ((i & k) == 0) == m;
            if ((ascending && arr[i] > arr[l]) || (!ascending && arr[i] < arr[l])) {
              int temp = arr[i];
              arr[i] = arr[l];
              arr[l] = temp;
            }
          }
        }
      }
    }
  }

  public static void main(String[] args) {
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56
    };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
