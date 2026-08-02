import java.util.Arrays;

public class classicthreesmoothcombsort {
  private static boolean is3Smooth(int n) {
    while (n % 6 == 0) {
      n /= 6;
    }
    while (n % 3 == 0) {
      n /= 3;
    }
    while (n % 2 == 0) {
      n /= 2;
    }
    return n == 1;
  }

  public static void sort(int[] array) {
    int length = array.length;
    for (int g = length - 1; g > 0; g--) {
      if (is3Smooth(g)) {
        for (int i = g; i < length; i++) {
          if (array[i - g] > array[i]) {
            int t = array[i - g];
            array[i - g] = array[i];
            array[i] = t;
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
