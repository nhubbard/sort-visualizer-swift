import java.util.Arrays;

public class weavesortiterative {
  public static void sort(int[] arr) {
    int n = arr.length;
    int end = n;
    int padded = 1;
    while (padded < end) {
      padded *= 2;
    }

    int i = 1;
    while (i < padded) {
      int j = 1;
      while (j <= i) {
        int k = 0;
        while (k < padded) {
          int d = padded / i / 2;
          int m = 0;
          int l = padded / j - d;
          while (l >= padded / j / 2) {
            int p = 0;
            while (p < d) {
              int a = k + m;
              int b = k + l + p;
              if (b < end && arr[a] > arr[b]) {
                int temp = arr[a];
                arr[a] = arr[b];
                arr[b] = temp;
              }
              p++;
              m++;
            }
            l -= d;
          }
          k += padded / j;
        }
        j *= 2;
      }
      i *= 2;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
