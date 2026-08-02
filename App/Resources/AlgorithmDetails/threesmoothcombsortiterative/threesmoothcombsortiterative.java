import java.util.Arrays;

public class threesmoothcombsortiterative {
  public static void sort(int[] arr) {
    int n = arr.length;
    if (n <= 1) {
      return;
    }
    int pow2 = (int) (Math.log(n - 1) / Math.log(2));
    for (int k = pow2; k >= 0; k--) {
      int pow3 = (int) ((Math.log(n) - k * Math.log(2)) / Math.log(3));
      for (int j = pow3; j >= 0; j--) {
        int gap = (int) (Math.pow(2, k) * Math.pow(3, j));
        for (int i = 0; i + gap < n; i++) {
          if (arr[i] > arr[i + gap]) {
            int t = arr[i];
            arr[i] = arr[i + gap];
            arr[i + gap] = t;
          }
        }
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
