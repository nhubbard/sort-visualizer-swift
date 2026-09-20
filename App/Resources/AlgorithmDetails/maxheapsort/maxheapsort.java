import java.util.Arrays;

public class maxheapsort {
  public static void sort(int[] arr) {
    int n = arr.length;
    for (int i = n / 2 - 1; i >= 0; i--) {
      siftDown(arr, i, n);
    }
    for (int i = n - 1; i > 0; i--) {
      int temp = arr[0];
      arr[0] = arr[i];
      arr[i] = temp;
      siftDown(arr, 0, i);
    }
  }

  private static void siftDown(int[] arr, int root, int size) {
    while (true) {
      int largest = root;
      int left = 2 * root + 1;
      int right = left + 1;
      if (left < size && arr[largest] < arr[left]) largest = left;
      if (right < size && arr[largest] < arr[right]) largest = right;
      if (largest == root) break;
      int temp = arr[root];
      arr[root] = arr[largest];
      arr[largest] = temp;
      root = largest;
    }
  }

  public static void main(String[] args) {
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56
    };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
