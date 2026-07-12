import java.util.Arrays;

public class basenmaxheapsort {
  private static final int BASE = 4;

  public static void siftDown(int[] arr, int node, int stop) {
    int left = node * BASE + 1;
    if (left >= stop) {
      return;
    }
    int maxIndex = left;
    for (int i = left + 1; i < left + BASE && i < stop; i++) {
      if (arr[maxIndex] < arr[i]) {
        maxIndex = i;
      }
    }
    if (arr[node] < arr[maxIndex]) {
      int temp = arr[node];
      arr[node] = arr[maxIndex];
      arr[maxIndex] = temp;
      siftDown(arr, maxIndex, stop);
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    for (int i = n - 1; i >= 0; i--) {
      siftDown(arr, i, n);
    }
    for (int end = n - 1; end > 0; end--) {
      int temp = arr[0];
      arr[0] = arr[end];
      arr[end] = temp;
      siftDown(arr, 0, end);
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
