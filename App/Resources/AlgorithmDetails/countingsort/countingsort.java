import java.util.Arrays;

public class countingsort {
  public static int[] sort(int arr[]) {
    int max = arr[0];
    for (int i = 1; i < arr.length; i++) {
      if (arr[i] > max) {
        max = arr[i];
      }
    }

    int[] counts = new int[max + 1];
    for (int value : arr) {
      counts[value]++;
    }
    for (int i = 1; i <= max; i++) {
      counts[i] += counts[i - 1];
    }

    int[] output = new int[arr.length];
    for (int i = arr.length - 1; i >= 0; i--) {
      counts[arr[i]]--;
      output[counts[arr[i]]] = arr[i];
    }
    return output;
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    array = sort(array);
    System.out.println(Arrays.toString(array));
  }
}
