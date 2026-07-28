import java.util.Arrays;

public class quadstoogesort {
  private static void quadStooge(int[] arr, int pos, int length) {
    if (length >= 2 && arr[pos] > arr[pos + length - 1]) {
      int temp = arr[pos];
      arr[pos] = arr[pos + length - 1];
      arr[pos + length - 1] = temp;
    }
    if (length <= 2) {
      return;
    }

    int len1 = length / 2;
    int len2 = (length + 1) / 2;
    int len3 = (len1 + 1) / 2 + (len2 + 1) / 2;

    quadStooge(arr, pos, len1);
    quadStooge(arr, pos + len1, len2);
    quadStooge(arr, pos + len1 / 2, len3);
    quadStooge(arr, pos + len1, len2);
    quadStooge(arr, pos, len1);
    if (length > 3) {
      quadStooge(arr, pos + len1 / 2, len3);
    }
  }

  public static void sort(int[] arr) {
    quadStooge(arr, 0, arr.length);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
