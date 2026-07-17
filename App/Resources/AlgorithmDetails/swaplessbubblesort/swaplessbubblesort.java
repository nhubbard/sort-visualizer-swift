import java.util.Arrays;

public class swaplessbubblesort {
  private static void swaplessBubbleSort(int arr[]) {
    int n = arr.length;
    int i = n;
    while (i > 0) {
      int last = 0;
      int pos = 0;
      int comp = arr[0];
      for (int j = 1; j < i; j++) {
        if (comp > arr[j]) {
          arr[j - 1] = arr[j];
          last = j;
        } else {
          if (pos + 1 < j) {
            arr[j - 1] = comp;
          }
          pos = j;
          comp = arr[j];
        }
      }
      arr[i - 1] = comp;
      i = last;
    }
  }

  public static void sort(int arr[]) {
    swaplessBubbleSort(arr);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
