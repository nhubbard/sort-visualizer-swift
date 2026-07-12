import java.util.Arrays;

public class bitonicsort {
  public static void sort(int[] arr) {
    int n = arr.length;
    for (int k = 2; k <= n; k *= 2) {
      for (int j = k / 2; j > 0; j /= 2) {
        for (int i = 0; i < n; i++) {
          int l = i ^ j;
          if (l > i) {
            if (((i & k) == 0) && (arr[i] > arr[l]) ||
                (((i & k) != 0) && (arr[i] < arr[l]))) {
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
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}