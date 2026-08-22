import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class mergebogosort {
  public static boolean isSorted(int[] arr, int start, int end) {
    for (int i = start; i < end - 1; i++) {
      if (arr[i] > arr[i + 1]) {
        return false;
      }
    }
    return true;
  }

  public static void sort(int[] arr, int start, int end) {
    if (start >= end - 1) {
      return;
    }
    int mid = (start + end) / 2;
    sort(arr, start, mid);
    sort(arr, mid, end);

    int[] saved = Arrays.copyOfRange(arr, start, end);

    while (!isSorted(arr, start, end)) {
      List<Integer> indices = new ArrayList<>();
      for (int i = 0; i < end - start; i++) {
        indices.add(i);
      }
      Collections.shuffle(indices);
      Set<Integer> highPositions = new HashSet<>(indices.subList(0, end - mid));

      int low = 0;
      int high = mid - start;
      for (int offset = 0; offset < end - start; offset++) {
        if (highPositions.contains(offset)) {
          arr[start + offset] = saved[high];
          high++;
        } else {
          arr[start + offset] = saved[low];
          low++;
        }
      }
    }
  }

  public static void sort(int[] arr) {
    sort(arr, 0, arr.length);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 14, 23};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
