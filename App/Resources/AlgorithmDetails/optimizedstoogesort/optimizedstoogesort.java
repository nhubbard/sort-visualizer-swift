import java.util.Arrays;

public class optimizedstoogesort {
  private static void forward(int[] arr, int left, int right) {
    while (left < right) {
      int index = right;
      while (left < index) {
        if (arr[left] > arr[index]) {
          int temp = arr[left];
          arr[left] = arr[index];
          arr[index] = temp;
        }
        left++;
        index--;
      }
      left = 0;
      right--;
    }
  }

  private static void backward(int[] arr, int left, int right) {
    int length = right;
    while (left < right) {
      int index = left;
      while (index < right) {
        if (arr[index] > arr[right]) {
          int temp = arr[index];
          arr[index] = arr[right];
          arr[right] = temp;
        }
        index++;
        right--;
      }
      left++;
      right = length;
    }
  }

  private static void exchange(int[] arr, int length) {
    int left = 0;
    int right = length - 1;
    while (left < right) {
      if (arr[left] > arr[right]) {
        int temp = arr[left];
        arr[left] = arr[right];
        arr[right] = temp;
      }
      left++;
      right--;
    }

    forward(arr, 0, length - 2);
    backward(arr, 1, length - 1);
  }

  public static void sort(int[] arr) {
    exchange(arr, arr.length);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
