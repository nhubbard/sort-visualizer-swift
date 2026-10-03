import java.util.Arrays;

public class bufferpartitionmergesort {
  public static void sort(int[] arr) {
    final int run = 8;
    for (int start = 0; start < arr.length; start += run) {
      int end = Math.min(start + run, arr.length);
      for (int i = start + 1; i < end; i++) {
        int value = arr[i];
        int j = i;
        while (j > start && arr[j - 1] > value) {
          arr[j] = arr[j - 1];
          j--;
        }
        arr[j] = value;
      }
    }

    int[] scratch = arr.clone();
    for (int width = run; width < arr.length; width *= 2) {
      for (int start = 0; start < arr.length; start += 2 * width) {
        int middle = Math.min(start + width, arr.length);
        int end = Math.min(start + 2 * width, arr.length);
        int left = start;
        int right = middle;
        for (int output = start; output < end; output++) {
          if (left < middle && (right >= end || arr[left] < arr[right])) {
            scratch[output] = arr[left++];
          } else {
            scratch[output] = arr[right++];
          }
        }
      }
      System.arraycopy(scratch, 0, arr, 0, arr.length);
    }
  }

  public static void main(String[] args) {
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56
    };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
