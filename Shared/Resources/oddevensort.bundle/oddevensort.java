import java.util.Arrays;

public class oddevensort {
  public static void sort(int[] arr) {
    int n = arr.length;
    boolean sorted = false;
    while (!sorted) {
      sorted = true;
      for (int i = 1; i < n - 1; i += 2) {
        if (arr[i] > arr[i + 1]) {
          int temp = arr[i];
          arr[i] = arr[i + 1];
          arr[i + 1] = temp;
          sorted = false;
        }
      }
      for (int i = 0; i < n - 1; i += 2) {
        if (arr[i] > arr[i + 1]) {
          int temp = arr[i];
          arr[i] = arr[i + 1];
          arr[i + 1] = temp;
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