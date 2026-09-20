import java.util.Arrays;

public class shellsort {
  public static void sort(int[] arr) {
    int n = arr.length;
    int[] gaps = {8861, 3938, 1750, 701, 301, 132, 57, 23, 10, 4, 1};
    for (int gap : gaps) {
      if (gap >= n) continue;
      for (int i = gap; i < n; i++) {
        for (int j = i; j >= gap && arr[j] < arr[j - gap]; j -= gap) {
          int temp = arr[j];
          arr[j] = arr[j - gap];
          arr[j - gap] = temp;
        }
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
