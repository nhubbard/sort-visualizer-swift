import java.util.Arrays;

public class lsdradixsort {
  public static void sort(int[] arr) {
    int n = arr.length;
    int maxValue = 0;
    for (int value : arr) {
      if (value > maxValue) maxValue = value;
    }
    int[] output = new int[n];
    int divisor = 1;
    while (true) {
      int[] counts = new int[4];
      for (int i = 0; i < n; i++) counts[(arr[i] / divisor) % 4]++;
      for (int digit = 1; digit < 4; digit++) counts[digit] += counts[digit - 1];
      for (int i = n - 1; i >= 0; i--) {
        int digit = (arr[i] / divisor) % 4;
        output[--counts[digit]] = arr[i];
      }
      System.arraycopy(output, 0, arr, 0, n);
      if (divisor > maxValue / 4) break;
      divisor *= 4;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
