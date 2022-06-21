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
                (((i & k) != 0) && (arr[i] < arr[j]))) {
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
    // Specific to bitonic sort: size must be power of 2.
    int[] items = new int[]{35, 74, 71, 72, 30, 53, 9, 0};
    sort(items);
    System.out.println(Arrays.toString(items));
  }
}
