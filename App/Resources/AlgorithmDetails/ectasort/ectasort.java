import java.util.Arrays;

public class ectasort {
  private static int minRun(int n) {
    while (n >= 32) {
      n = (n + 1) / 2;
    }
    return n;
  }

  private static void insertion(int[] arr, int start, int end) {
    for (int i = start + 1; i < end; i++) {
      int value = arr[i];
      int low = start;
      int high = i;
      while (low < high) {
        int middle = low + (high - low) / 2;
        if (arr[middle] > value) {
          high = middle;
        } else {
          low = middle + 1;
        }
      }
      for (int j = i; j > low; j--) {
        arr[j] = arr[j - 1];
      }
      arr[low] = value;
    }
  }

  private static void mergeBackward(int[] arr, int start, int middle, int end, int workspace) {
    int count = end - middle;
    System.arraycopy(arr, middle, arr, workspace, count);
    int left = middle - 1;
    int right = workspace + count - 1;
    int output = end - 1;
    while (left >= start && right >= workspace) {
      if (arr[left] > arr[right]) {
        arr[output--] = arr[left--];
      } else {
        arr[output--] = arr[right--];
      }
    }
    while (right >= workspace) {
      arr[output--] = arr[right--];
    }
  }

  private static void sortSegment(int[] arr, int start, int end, int workspace, int run) {
    for (int lower = start; lower < end; lower += run) {
      insertion(arr, lower, Math.min(lower + run, end));
    }
    for (int width = run; width < end - start; width *= 2) {
      for (int lower = start; lower < end; lower += 2 * width) {
        int middle = Math.min(lower + width, end);
        int upper = Math.min(lower + 2 * width, end);
        if (middle < upper) {
          mergeBackward(arr, lower, middle, upper, workspace);
        }
      }
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n < 2) {
      return;
    }
    int run = minRun(n);
    if (n <= 32) {
      insertion(arr, 0, n);
      return;
    }
    int half = n / 2;
    int[] buffer = Arrays.copyOfRange(arr, half, 2 * half);
    sortSegment(arr, 0, half, half, run);
    System.arraycopy(buffer, 0, arr, half, half);
    System.arraycopy(arr, 0, buffer, 0, half);
    sortSegment(arr, half, n, 0, run);
    int left = 0;
    int right = half;
    int output = 0;
    while (left < half && right < n) {
      if (buffer[left] <= arr[right]) {
        arr[output++] = buffer[left++];
      } else {
        arr[output++] = arr[right++];
      }
    }
    while (left < half) {
      arr[output++] = buffer[left++];
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
