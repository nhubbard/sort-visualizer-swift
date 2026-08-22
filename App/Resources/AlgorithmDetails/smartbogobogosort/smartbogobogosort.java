import java.util.Arrays;

public class smartbogobogosort {
  public static void sort(int[] arr, int length) {
    if (length == 1) {
      return;
    }
    sort(arr, length - 1);
    while (arr[length - 2] > arr[length - 1]) {
      for (int i = length - 1; i > 0; i--) {
        int j = (int) (Math.random() * (i + 1));
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
      }
      sort(arr, length - 1);
    }
  }

  public static void sort(int[] arr) {
    sort(arr, arr.length);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 14, 23};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
