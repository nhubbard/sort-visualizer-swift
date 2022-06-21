import java.util.Arrays;

public class pancakesort {
  public static void flip(int[] arr, int n) {
    int left = 0;
    while (left < n) {
      int temp = arr[left];
      arr[left] = arr[n];
      arr[n] = temp;
      n--;
      left++;
    }
  }
  
  public static int maxIndex(int[] arr, int n) {
    int index = 0;
    for (int i = 0; i < n; i++) {
      if (arr[i] > arr[index]) {
        index = i;
      }
    }
    return index;
  }
  
  public static void sort(int[] arr) {
    int n = arr.length;
    int max;
    while (n > 1) {
      max = maxIndex(arr, n);
      if (max != n) {
        flip(arr, max);
        flip(arr, n - 1);
      }
      n--;
    }
  }

  public static void main(String[] args) {
    int[] items = new int[]{35, 95, 74, 71, 72, 30, 96, 53, 9, 0};
    sort(items);
    System.out.println(Arrays.toString(items));
  }
}
