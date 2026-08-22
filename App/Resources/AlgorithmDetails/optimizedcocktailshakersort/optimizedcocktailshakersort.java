import java.util.Arrays;

public class optimizedcocktailshakersort {
  public static void sort(int[] arr) {
    int start = 0;
    int end = arr.length - 1;
    while (start < end) {
      int consecSorted = 1;
      for (int i = start; i < end; i++) {
        if (arr[i] > arr[i + 1]) {
          int temp = arr[i];
          arr[i] = arr[i + 1];
          arr[i + 1] = temp;
          consecSorted = 1;
        } else {
          consecSorted++;
        }
      }
      end -= consecSorted;

      consecSorted = 1;
      for (int j = end; j > start; j--) {
        if (arr[j - 1] > arr[j]) {
          int temp = arr[j - 1];
          arr[j - 1] = arr[j];
          arr[j] = temp;
          consecSorted = 1;
        } else {
          consecSorted++;
        }
      }
      start += consecSorted;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
