import java.util.Arrays;

public final class triangularheapsort {
  static int triangularRoot(int val) {
    return ((int) Math.sqrt((double) (8 * val + 1)) - 1) / 2;
  }

  static void siftDown(int[] array, int root, int size) {
    while (true) {
      int row = triangularRoot(root);
      int left = root + row + 1;
      if (left >= size) break;
      int right = left + 1;
      int largest = root;
      if (array[largest] < array[left]) largest = left;
      if (right < size && array[largest] < array[right]) largest = right;
      if (largest == root) break;
      int temp = array[root];
      array[root] = array[largest];
      array[largest] = temp;
      root = largest;
    }
  }

  static void heapify(int[] array, int length) {
    for (int i = length - 1; i >= 0; i--) {
      siftDown(array, i, length);
    }
  }

  static void sort(int[] array) {
    int n = array.length;
    if (n <= 1) return;
    heapify(array, n);
    for (int i = 1; i < n - 1; i++) {
      int temp = array[0];
      array[0] = array[n - i];
      array[n - i] = temp;
      siftDown(array, 0, n - i);
    }
    if (array[0] > array[1]) {
      int temp = array[0];
      array[0] = array[1];
      array[1] = temp;
    }
  }

  public static void main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
