import java.util.Arrays;

public class bufferedstoogesort {
  private static void bufferedStoogeSort(int[] arr, int start, int stop) {
    if (stop - start > 1) {
      if (stop - start == 2 && arr[start] > arr[stop - 1]) {
        int temp = arr[start];
        arr[start] = arr[stop - 1];
        arr[stop - 1] = temp;
      }
      if (stop - start > 2) {
        int width = stop - start;
        int third = (width + 2) / 3 + start;
        int twoThird = (2 * width + 2) / 3 + start;
        if (twoThird - third < third) {
          twoThird--;
        }
        if ((width - 2) % 3 == 0) {
          twoThird--;
        }

        bufferedStoogeSort(arr, third, twoThird);
        bufferedStoogeSort(arr, twoThird, stop);

        int left = third;
        int right = twoThird;
        int bufferStart = start;
        while (left < twoThird && right < stop) {
          if (arr[left] > arr[right]) {
            int temp = arr[bufferStart];
            arr[bufferStart] = arr[right];
            arr[right] = temp;
            right++;
          } else {
            int temp = arr[bufferStart];
            arr[bufferStart] = arr[left];
            arr[left] = temp;
            left++;
          }
          bufferStart++;
        }
        while (right < stop) {
          int temp = arr[bufferStart];
          arr[bufferStart] = arr[right];
          arr[right] = temp;
          right++;
          bufferStart++;
        }

        bufferedStoogeSort(arr, twoThird, stop);

        left = twoThird - 1;
        right = stop - 1;
        while (right > left && left >= start) {
          if (arr[left] > arr[right]) {
            for (int i = left; i < right; i++) {
              int temp = arr[i];
              arr[i] = arr[i + 1];
              arr[i + 1] = temp;
            }
            left--;
          }
          right--;
        }
      }
    }
  }

  public static void sort(int[] arr) {
    bufferedStoogeSort(arr, 0, arr.length);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
