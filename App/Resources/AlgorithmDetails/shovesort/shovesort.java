import java.util.Arrays;

public class shovesort {
  public static void sort(int[] arr) {
    int end = arr.length;
    int i = 0;
    while (i < end - 1) {
      if (arr[i] > arr[i + 1]) {
        for (int f = i; f < end - 1; f++) {
          int temp = arr[f];
          arr[f] = arr[f + 1];
          arr[f + 1] = temp;
        }
        if (i > 0) {
          i--;
        }
        continue;
      }
      i++;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
