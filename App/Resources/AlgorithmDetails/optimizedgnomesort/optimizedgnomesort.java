import java.util.Arrays;

public class optimizedgnomesort {
  public static void sort(int arr[]) {
    for (int i = 1; i < arr.length; i++) {
      int pos = i;
      while (pos > 0 && arr[pos - 1] > arr[pos]) {
        int temp = arr[pos - 1];
        arr[pos - 1] = arr[pos];
        arr[pos] = temp;
        pos--;
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
