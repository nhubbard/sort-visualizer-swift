import java.util.Arrays;

public class combsort {
  public static void sort(int[] arr) {
    int n = arr.length;
    int sm;
    double shrink = 1.3;
    int gap = n;
    boolean sorted = false;
    while (!sorted) {
      gap = (int)Math.floor(gap / shrink);
      if (gap <= 1) {
        sorted = true;
        gap = 1;
      }
      for (int i = 0; i < n - gap; i++) {
        sm = gap + i;
        if (arr[i] > arr[sm]) {
          int temp = arr[i];
          arr[i] = arr[sm];
          arr[sm] = temp;
          sorted = false;
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
