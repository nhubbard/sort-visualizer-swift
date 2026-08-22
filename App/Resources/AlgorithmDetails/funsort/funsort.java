import java.util.Arrays;

public class funsort {
  public static boolean compositeLess(int[] arr, int[] key, int mid, int i) {
    if (arr[mid] < arr[i]) {
      return true;
    }
    if (arr[mid] == arr[i]) {
      return key[mid] < key[i];
    }
    return false;
  }

  public static int binarySearch(int[] arr, int[] key, int n, int i) {
    int start = 0;
    int end = n - 1;
    while (start < end) {
      int mid = (start + end) / 2;
      if (compositeLess(arr, key, mid, i)) {
        start = mid + 1;
      } else {
        end = mid;
      }
    }
    return start;
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    int[] key = new int[n];
    for (int i = 0; i < n; i++) {
      key[i] = i;
    }

    for (int i = 1; i < n; i++) {
      boolean done = false;
      while (!done) {
        int pos = binarySearch(arr, key, n, i);
        if (pos == i) {
          done = true;
        } else if (i < pos - 1) {
          int t = arr[i];
          arr[i] = arr[pos - 1];
          arr[pos - 1] = t;
          int tk = key[i];
          key[i] = key[pos - 1];
          key[pos - 1] = tk;
        } else {
          int t = arr[i];
          arr[i] = arr[pos];
          arr[pos] = t;
          int tk = key[i];
          key[i] = key[pos];
          key[pos] = tk;
        }
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
