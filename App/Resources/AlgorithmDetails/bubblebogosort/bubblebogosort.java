import java.util.Arrays;

public class bubblebogosort {
  public static void sort(int[] a) {
    int n = a.length;
    if (n < 2) return;
    boolean swapped = true;
    while (swapped) {
      swapped = false;
      for (int i = 0; i + 1 < n; i++)
        if (a[i] > a[i + 1]) {
          int held = a[i];
          a[i] = a[i + 1];
          a[i + 1] = held;
          swapped = true;
        }
    }
  }

  public static void main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
