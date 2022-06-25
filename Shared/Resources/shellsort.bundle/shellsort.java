import java.util.Arrays;

public class shellsort {
  public static void sort(int[] arr) {
    int n = arr.length;
    for (int i = n / 2; i > 0; i /= 2) {
      for (int j = i; j < n; j++) {
        for (int k = j - i; k >= 0; k -= i) {
          if (arr[k + i] >= arr[k]) {
            break;
          } else {
            int temp = arr[k];
            arr[k] = arr[k + i];
            arr[k + i] = temp;
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