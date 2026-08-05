import java.util.Arrays;

public final class outofplaceheapsort {
  static void siftDown(int[] arr, int root, int size) {
    int index = root;
    while (2 * index + 1 < size) {
      int child = 2 * index + 1;
      if (child + 1 < size && arr[child + 1] > arr[child]) {
        child++;
      }
      index = child;
    }
    int rootValue = arr[root];
    while (rootValue > arr[index]) {
      index = (index - 1) / 2;
    }
    while (index != root) {
      int temp = arr[root];
      arr[root] = arr[index];
      arr[index] = temp;
      index = (index - 1) / 2;
    }
  }

  static void heapify(int[] arr, int length) {
    for (int i = (length - 1) / 2; i >= 0; i--) {
      siftDown(arr, i, length);
    }
  }

  static void findNext(int[] arr, int size) {
    int hole = 0;
    int left = 1;
    int right = 2;
    while (right < size && !(arr[left] == -1 && arr[right] == -1)) {
      if (arr[left] == -1) {
        int temp = arr[hole];
        arr[hole] = arr[right];
        arr[right] = temp;
        hole = right;
      } else if (arr[right] == -1) {
        int temp = arr[hole];
        arr[hole] = arr[left];
        arr[left] = temp;
        hole = left;
      } else if (arr[right] > arr[left]) {
        int temp = arr[hole];
        arr[hole] = arr[right];
        arr[right] = temp;
        hole = right;
      } else {
        int temp = arr[hole];
        arr[hole] = arr[left];
        arr[left] = temp;
        hole = left;
      }
      left = 2 * hole + 1;
      right = left + 1;
    }
    if (left < size && arr[left] != -1) {
      int temp = arr[hole];
      arr[hole] = arr[left];
      arr[left] = temp;
    }
  }

  public static int[] sort(int[] arr) {
    int n = arr.length;
    int[] output = new int[n];
    if (n <= 1) {
      if (n == 1) {
        output[0] = arr[0];
      }
      return output;
    }
    heapify(arr, n);
    for (int i = n - 1; i >= 0; i--) {
      output[i] = arr[0];
      arr[0] = -1;
      findNext(arr, n);
    }
    return output;
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    int[] output = sort(array);
    System.out.println(Arrays.toString(output));
  }
}
