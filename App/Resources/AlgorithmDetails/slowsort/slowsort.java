import java.util.Arrays;

public class slowsort {
  private static void slowSort(int arr[], int i, int j) {
    if (i >= j) {
      return;
    }
    int m = i + (j - i) / 2;
    slowSort(arr, i, m);
    slowSort(arr, m + 1, j);
    if (arr[m] > arr[j]) {
      int temp = arr[m];
      arr[m] = arr[j];
      arr[j] = temp;
    }
    slowSort(arr, i, j - 1);
  }

  public static void sort(int arr[]) {
    slowSort(arr, 0, arr.length - 1);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
