import java.util.Arrays;

public class badsort {
  private static void sort(int[] array) {
    int currentLen = array.length;
    for (int i = 0; i < currentLen; i++) {
      int shortest = i;

      for (int j = i; j < currentLen; j++) {
        boolean isShortest = true;
        for (int k = j + 1; k < currentLen; k++) {
          if (array[j] > array[k]) {
            isShortest = false;
            break;
          }
        }
        if (isShortest) {
          shortest = j;
          break;
        }
      }

      int temp = array[i];
      array[i] = array[shortest];
      array[shortest] = temp;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
