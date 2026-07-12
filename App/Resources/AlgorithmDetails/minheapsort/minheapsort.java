import java.util.Arrays;

public class minheapsort {
  private static void siftDown(int arr[], int root, int size) {
    while (true) {
      int smallest = root;
      int left = 2 * root + 1;
      int right = 2 * root + 2;
      if (left < size && arr[left] < arr[smallest]) {
        smallest = left;
      }
      if (right < size && arr[right] < arr[smallest]) {
        smallest = right;
      }
      if (smallest == root) {
        break;
      }
      int temp = arr[root];
      arr[root] = arr[smallest];
      arr[smallest] = temp;
      root = smallest;
    }
  }

  private static void heapify(int arr[]) {
    for (int i = arr.length / 2 - 1; i >= 0; i--) {
      siftDown(arr, i, arr.length);
    }
  }

  private static void reverse(int arr[]) {
    int low = 0, high = arr.length - 1;
    while (low < high) {
      int temp = arr[low];
      arr[low] = arr[high];
      arr[high] = temp;
      low++;
      high--;
    }
  }

  public static void sort(int arr[]) {
    heapify(arr);
    for (int end = arr.length - 1; end > 0; end--) {
      int temp = arr[0];
      arr[0] = arr[end];
      arr[end] = temp;
      siftDown(arr, 0, end);
    }
    reverse(arr);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
