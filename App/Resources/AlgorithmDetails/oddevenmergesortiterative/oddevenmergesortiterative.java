import java.util.Arrays;

public class oddevenmergesortiterative {
  public static void sort(int[] arr) {
    int n = arr.length;

    for (int p = 1; p < n; p += p) {
      for (int k = p; k > 0; k /= 2) {
        for (int j = k % p; j + k < n; j += k + k) {
          for (int i = 0; i < k; i++) {
            if ((i + j) / (p + p) == (i + j + k) / (p + p)) {
              if (i + j + k < n) {
                if (arr[i + j] > arr[i + j + k]) {
                  int temp = arr[i + j];
                  arr[i + j] = arr[i + j + k];
                  arr[i + j + k] = temp;
                }
              }
            }
          }
        }
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}