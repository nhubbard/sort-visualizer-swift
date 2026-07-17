import java.util.Arrays;

public class selectionbogosort {
  public static int minFrom(int[] arr, int i) {
    int m = arr[i];
    for (int k = i + 1; k < arr.length; k++) {
      if (arr[k] < m) {
        m = arr[k];
      }
    }
    return m;
  }

  public static void sort(int arr[]) {
    int n = arr.length;
    for (int i = 0; i < n; i++) {
      while (arr[i] != minFrom(arr, i)) {
        int j = i + (int) (Math.random() * (n - i));
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 14, 23};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
