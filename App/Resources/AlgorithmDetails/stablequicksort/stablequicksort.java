import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class stablequicksort {
  public static int stablePartition(int[] arr, int start, int end) {
    int pivotValue = arr[start];
    List<Integer> leftList = new ArrayList<>();
    List<Integer> rightList = new ArrayList<>();

    for (int i = start + 1; i <= end; i++) {
      if (arr[i] < pivotValue) {
        leftList.add(arr[i]);
      } else {
        rightList.add(arr[i]);
      }
    }

    int writeIndex = start;
    for (int v : leftList) {
      arr[writeIndex++] = v;
    }
    int pivotIndex = writeIndex;
    arr[writeIndex++] = pivotValue;
    for (int v : rightList) {
      arr[writeIndex++] = v;
    }
    return pivotIndex;
  }

  public static void stableQuickSort(int[] arr, int start, int end) {
    if (start < end) {
      int p = stablePartition(arr, start, end);
      stableQuickSort(arr, start, p - 1);
      stableQuickSort(arr, p + 1, end);
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    stableQuickSort(arr, 0, n - 1);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
