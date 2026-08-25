import java.util.Arrays;

public class optimizedbottomupmergesort {
  static final int BLOCK_SIZE = 16;

  static void binaryInsertionSort(int[] arr, int lo, int hi) {
    for (int i = lo + 1; i < hi; i++) {
      int key = arr[i];
      int left = lo;
      int right = i;
      while (left < right) {
        int mid = (left + right) / 2;
        if (arr[mid] <= key) {
          left = mid + 1;
        } else {
          right = mid;
        }
      }
      for (int j = i; j > left; j--) {
        arr[j] = arr[j - 1];
      }
      arr[left] = key;
    }
  }

  static void merge(int[] src, int[] dst, int low, int mid, int high) {
    int i = low;
    int j = mid;
    int k = low;
    while (i < mid && j < high) {
      if (src[i] <= src[j]) {
        dst[k++] = src[i++];
      } else {
        dst[k++] = src[j++];
      }
    }
    while (i < mid) {
      dst[k++] = src[i++];
    }
    while (j < high) {
      dst[k++] = src[j++];
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n < BLOCK_SIZE) {
      binaryInsertionSort(arr, 0, n);
      return;
    }

    // Pre-pass: sort fixed-size blocks with binary insertion sort so the merge phase can
    // start from already-sorted runs instead of single elements.
    for (int low = 0; low < n; low += BLOCK_SIZE) {
      binaryInsertionSort(arr, low, Math.min(low + BLOCK_SIZE, n));
    }

    // Merge phase: ping-pong between arr and scratch, alternating direction every pass,
    // instead of always merging into scratch and copying the whole buffer back.
    int[] scratch = new int[n];
    int[] src = arr;
    int[] dst = scratch;
    int passes = 0;
    for (int width = BLOCK_SIZE; width < n; width *= 2) {
      for (int low = 0; low < n; low += 2 * width) {
        int mid = Math.min(low + width, n);
        int high = Math.min(low + 2 * width, n);
        if (mid < high) {
          merge(src, dst, low, mid, high);
        } else {
          System.arraycopy(src, low, dst, low, mid - low);
        }
      }
      int[] t = src;
      src = dst;
      dst = t;
      passes++;
    }

    // An even number of passes lands the sorted result back in arr on its own; an odd
    // number leaves it in scratch, needing this one explicit copy back.
    if (passes % 2 == 1) {
      System.arraycopy(src, 0, arr, 0, n);
    }
  }

  public static void main(String[] args) {
    int[] array =
        new int[] {
          81, 14, 3, 94, 35, 31, 28, 17, 94, 13, 86, 94, 69, 11, 75, 54,
          4, 3, 11, 27, 29, 64, 77, 3, 71, 25, 91, 83, 89, 69, 53, 28,
          57, 75, 35, 0, 97, 20, 89, 54
        };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
