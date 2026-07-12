import java.util.Arrays;

public class exchangebogosort {
  public static boolean isSorted(int[] arr) {
    for (int i = 1; i < arr.length; i++) {
      if (arr[i - 1] > arr[i]) {
        return false;
      }
    }
    return true;
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    while (!isSorted(arr)) {
      int i = (int) (Math.random() * n);
      int j = (int) (Math.random() * n);
      if ((i < j && arr[i] > arr[j]) || (i > j && arr[i] < arr[j])) {
        int t = arr[i];
        arr[i] = arr[j];
        arr[j] = t;
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
