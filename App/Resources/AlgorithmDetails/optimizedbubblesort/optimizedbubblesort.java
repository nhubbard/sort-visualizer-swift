import java.util.Arrays;

public class optimizedbubblesort {
  public static void sort(int arr[]) {
    int i = arr.length - 1;
    while (i > 0) {
      int consecSorted = 1;
      for (int j = 0; j < i; j++) {
        if (arr[j] > arr[j + 1]) {
          int temp = arr[j];
          arr[j] = arr[j + 1];
          arr[j + 1] = temp;
          consecSorted = 1;
        } else {
          consecSorted++;
        }
      }
      i -= consecSorted;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
