import java.util.Arrays;

public class pairwisesortiterative {
  public static void sort(int[] arr) {
    int length = arr.length;
    int a = 1;
    while (a < length) {
      int b = a;
      int c = 0;
      while (b < length) {
        if (arr[b - a] > arr[b]) {
          int temp = arr[b - a];
          arr[b - a] = arr[b];
          arr[b] = temp;
        }
        c = (c + 1) % a;
        b++;
        if (c == 0) {
          b += a;
        }
      }
      a *= 2;
    }

    a /= 4;
    int e = 1;
    while (a > 0) {
      int d = e;
      while (d > 0) {
        int b = (d + 1) * a;
        int c = 0;
        while (b < length) {
          if (arr[b - (d * a)] > arr[b]) {
            int temp = arr[b - (d * a)];
            arr[b - (d * a)] = arr[b];
            arr[b] = temp;
          }
          c = (c + 1) % a;
          b++;
          if (c == 0) {
            b += a;
          }
        }
        d /= 2;
      }
      a /= 2;
      e = (e * 2) + 1;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
