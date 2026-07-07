import java.util.Arrays;

public class burntpancakesort {
  public static void flip(int[] arr, int end) {
    int start = 0;
    while (start < end) {
      int temp = arr[start];
      arr[start] = arr[end];
      arr[end] = temp;
      start++;
      end--;
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    for (int i = n - 1; i > 0; i--) {
      int max = 0;
      for (int j = max + 1; j <= i; j++) {
        if (arr[j] > arr[max]) {
          max = j;
        }
      }
      if (max != i) {
        flip(arr, max);
        flip(arr, i);
        flip(arr, i - 1);
        flip(arr, max - 1);
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