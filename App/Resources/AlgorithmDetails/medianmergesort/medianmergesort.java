import java.util.Arrays;

public class medianmergesort {
  private static void mergeSort(int[] arr, int[] scratch, int start, int end) {
    if (end - start < 2) {
      return;
    }
    int middle = (start + end) / 2;
    mergeSort(arr, scratch, start, middle);
    mergeSort(arr, scratch, middle, end);
    int left = start;
    int right = middle;
    int dest = start;
    while (left < middle && right < end) {
      scratch[dest++] = arr[left] <= arr[right] ? arr[left++] : arr[right++];
    }
    while (left < middle) {
      scratch[dest++] = arr[left++];
    }
    while (right < end) {
      scratch[dest++] = arr[right++];
    }
    System.arraycopy(scratch, start, arr, start, end - start);
  }

  private static int medianOfThree(int x, int y, int z) {
    if (x > y) {
      int t = x;
      x = y;
      y = t;
    }
    if (y > z) {
      int t = y;
      y = z;
      z = t;
    }
    if (x > y) {
      int t = x;
      x = y;
      y = t;
    }
    return y;
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    int[] scratch = new int[n];
    int start = 0;
    int end = n;
    while (end - start > 16) {
      int pivot = medianOfThree(arr[start], arr[(start + end - 1) / 2], arr[end - 1]);
      int left = start;
      int right = end - 1;
      while (left <= right) {
        while (left <= right && arr[left] < pivot) {
          left++;
        }
        while (left <= right && arr[right] > pivot) {
          right--;
        }
        if (left <= right) {
          int t = arr[left];
          arr[left++] = arr[right];
          arr[right--] = t;
        }
      }
      if (left == start || left == end) {
        mergeSort(arr, scratch, start, end);
        return;
      }
      if (left - start <= end - left) {
        mergeSort(arr, scratch, start, left);
        start = left;
      } else {
        mergeSort(arr, scratch, left, end);
        end = left;
      }
    }
    for (int i = start + 1; i < end; i++) {
      int value = arr[i];
      int j = i;
      while (j > start && arr[j - 1] > value) {
        arr[j] = arr[--j];
      }
      arr[j] = value;
    }
  }

  public static void main(String[] args) {
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56,
      10, 2, 95, 46, 21, 74, 6, 38
    };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
