import java.util.Arrays;

public class indexsort {
  public static void sort(int[] arr) {
    int n = arr.length;
    int minValue = arr[0];
    for (int i = 1; i < n; i++) {
      if (arr[i] < minValue) {
        minValue = arr[i];
      }
    }

    for (int i = 0; i < n; i++) {
      int cmpCount = 0;
      while (arr[i] - minValue != i && cmpCount < n) {
        int j = arr[i] - minValue;
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
        cmpCount++;
      }
      if (cmpCount >= n - 1) {
        break;
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {7, 3, 14, 0, 9, 5, 12, 1, 15, 4, 10, 2, 13, 6, 11, 8};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
