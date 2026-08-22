import java.util.Arrays;

public class bubblebogosort {
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
      int index = (int) (Math.random() * (n - 1));
      if (arr[index] > arr[index + 1]) {
        int t = arr[index];
        arr[index] = arr[index + 1];
        arr[index + 1] = t;
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
