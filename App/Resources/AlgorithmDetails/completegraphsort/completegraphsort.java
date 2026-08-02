import java.util.Arrays;

public class completegraphsort {
  public static void compSwap(int[] arr, int a, int b) {
    if (arr[a] > arr[b]) {
      int tmp = arr[a];
      arr[a] = arr[b];
      arr[b] = tmp;
    }
  }

  public static void split(int[] arr, int a, int m, int b) {
    if (b - a < 2) {
      return;
    }
    int c = 0;
    int len1 = (b - a) / 2;
    boolean odd = (b - a) % 2 == 1;
    if (odd) {
      if (m - a > b - m) {
        c = a++;
      } else {
        c = --b;
      }
    }
    for (int s = 0; s < len1; s++) {
      int i = a;
      for (int j = s; j < len1; j++) {
        compSwap(arr, i++, m + j);
      }
      for (int j = 0; j < s; j++) {
        compSwap(arr, i++, m + j);
      }
    }
    if (odd) {
      if (c < m) {
        for (int j = 0; j < len1; j++) {
          compSwap(arr, c, m + j);
        }
      } else {
        for (int j = 0; j < len1; j++) {
          compSwap(arr, a + j, c);
        }
      }
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    int d = 2;
    int end = 1 << (int) (Math.log(n - 1) / Math.log(2) + 1);
    while (d <= end) {
      int i = 0;
      int dec = 0;
      while (i < n) {
        int j = i;
        dec += n;
        while (dec >= d) {
          dec -= d;
          j++;
        }
        int k = j;
        dec += n;
        while (dec >= d) {
          dec -= d;
          k++;
        }
        split(arr, i, j, k);
        i = k;
      }
      d *= 2;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
