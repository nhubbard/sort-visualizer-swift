import java.util.Arrays;

public class flippedminheapsort {
  public static int idx(int p, int n) {
    return n - p;
  }

  public static void siftDown(int[] arr, int root, int dist, int n) {
    while (root <= dist / 2) {
      int leaf = 2 * root;
      if (leaf < dist && arr[idx(leaf, n)] > arr[idx(leaf + 1, n)]) {
        leaf += 1;
      }
      if (arr[idx(root, n)] > arr[idx(leaf, n)]) {
        int temp = arr[idx(root, n)];
        arr[idx(root, n)] = arr[idx(leaf, n)];
        arr[idx(leaf, n)] = temp;
        root = leaf;
      } else {
        break;
      }
    }
  }

  public static void sort(int arr[]) {
    int n = arr.length;

    int i = n / 2;
    while (i >= 1) {
      siftDown(arr, i, n, n);
      i -= 1;
    }

    i = n;
    while (i > 1) {
      int temp = arr[idx(1, n)];
      arr[idx(1, n)] = arr[idx(i, n)];
      arr[idx(i, n)] = temp;
      siftDown(arr, 1, i - 1, n);
      i -= 1;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
