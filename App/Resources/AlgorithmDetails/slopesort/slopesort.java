import java.util.Arrays;

public class slopesort {
  public static void sort(int[] arr) {
    int n = arr.length;
    for (int start = 1; start < n; start++) {
      int i = start;
      int k = start - 1;
      while (k >= 0) {
        if (arr[i] < arr[k]) {
          int temp = arr[i];
          arr[i] = arr[k];
          arr[k] = temp;
        }
        k--;
        i--;
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
