import java.util.Arrays;

public class radixsort {
  public static void sort(int[] arr) {
    int n = arr.length;
    int[][] bucket = new int[10][10];
    int[] bucketCount = new int[10];
    int i, j, k, r, nop = 0, divisor = 1, lar, pass;
    lar = Arrays.stream(arr).summaryStatistics().getMax();
    while (lar > 0) {
      nop++;
      lar /= 10;
    }
    for (pass = 0; pass < nop; pass++) {
      for (i = 0; i < 10; i++) {
        bucketCount[i] = 0;
      }
      for (i = 0; i < n; i++) {
        r = (arr[i] / divisor) % 10;
        bucket[r][bucketCount[r]] = arr[i];
        bucketCount[r] += 1;
      }
      i = 0;
      for (k = 0; k < 10; k++) {
        for (j = 0; j < bucketCount[k]; j++) {
          arr[i] = bucket[k][j];
          i++;
        }
      }
      divisor *= 10;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}