import java.util.Arrays;

public class cyclesort {
  private static void cycleSort(int arr[]) {
    int n = arr.length;
    for (int cycleStart = 0; cycleStart < n - 1; cycleStart++) {
      int item = arr[cycleStart];
      int pos = cycleStart;
      for (int i = cycleStart + 1; i < n; i++) {
        if (arr[i] < item) pos++;
      }
      if (pos == cycleStart) continue;

      while (item == arr[pos]) pos++;
      int temp = arr[pos];
      arr[pos] = item;
      item = temp;

      while (pos != cycleStart) {
        pos = cycleStart;
        for (int i = cycleStart + 1; i < n; i++) {
          if (arr[i] < item) pos++;
        }
        while (item == arr[pos]) pos++;
        temp = arr[pos];
        arr[pos] = item;
        item = temp;
      }
    }
  }

  public static void sort(int arr[]) {
    cycleSort(arr);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
