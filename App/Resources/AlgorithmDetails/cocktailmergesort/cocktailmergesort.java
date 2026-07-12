import java.util.Arrays;

public class cocktailmergesort {
  private static int minRunLength(int n) {
    int r = 0;
    while (n >= 64) {
      r |= n & 1;
      n >>= 1;
    }
    return n + r;
  }

  private static void cocktailShakerSort(int[] arr, int start, int end) {
    int length = end - start;
    if (length <= 1) {
      return;
    }
    int i = 0;
    while (i < length / 2) {
      boolean isSorted = true;
      int j = i;
      while (j < length - i - 1) {
        if (arr[start + j] > arr[start + j + 1]) {
          int temp = arr[start + j];
          arr[start + j] = arr[start + j + 1];
          arr[start + j + 1] = temp;
          isSorted = false;
        }
        j++;
      }
      j = length - i - 1;
      while (j > i) {
        if (arr[start + j - 1] > arr[start + j]) {
          int temp = arr[start + j - 1];
          arr[start + j - 1] = arr[start + j];
          arr[start + j] = temp;
          isSorted = false;
        }
        j--;
      }
      if (isSorted) {
        break;
      }
      i++;
    }
  }

  private static void merge(int[] arr, int start, int mid, int end) {
    int leftLength = mid - start;
    int rightLength = end - mid;
    int[] left = Arrays.copyOfRange(arr, start, mid);
    int[] right = Arrays.copyOfRange(arr, mid, end);
    int i = 0, j = 0, k = start;
    while (i < leftLength && j < rightLength) {
      if (left[i] <= right[j]) {
        arr[k] = left[i];
        i++;
      } else {
        arr[k] = right[j];
        j++;
      }
      k++;
    }
    while (i < leftLength) {
      arr[k] = left[i];
      i++;
      k++;
    }
    while (j < rightLength) {
      arr[k] = right[j];
      j++;
      k++;
    }
  }

  public static void cocktailMergeSort(int[] arr) {
    int n = arr.length;
    if (n <= 1) {
      return;
    }
    int minRun = minRunLength(n);
    if (n == minRun) {
      cocktailShakerSort(arr, 0, n);
      return;
    }
    int i = 0;
    while (i <= n - minRun) {
      cocktailShakerSort(arr, i, i + minRun);
      i += minRun;
    }
    if (i < n) {
      cocktailShakerSort(arr, i, n);
    }
    int width = minRun;
    while (width < n) {
      i = 0;
      while (i < n) {
        int mid = Math.min(i + width, n);
        int end = Math.min(i + 2 * width, n);
        if (mid < end) {
          merge(arr, i, mid, end);
        }
        i += 2 * width;
      }
      width *= 2;
    }
  }

  public static void sort(int[] arr) {
    cocktailMergeSort(arr);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
