import java.util.Arrays;

public class iterativetopdownmergesort {
  public static void sort(int[] arr) {
    int n = arr.length;
    if (n < 2) return;
    int[] scratch = new int[n];
    int subarrayCount = 1;
    while (subarrayCount < n) {
      subarrayCount *= 2;
    }

    while (subarrayCount > 1) {
      for (int i = 0; i < subarrayCount; i += 2) {
        int low = n * i / subarrayCount;
        int mid = n * (i + 1) / subarrayCount;
        int high = n * (i + 2) / subarrayCount;
        merge(arr, scratch, low, mid, high);
      }
      subarrayCount /= 2;
    }
  }

  private static void merge(int[] arr, int[] scratch, int low, int mid, int high) {
    int left = low;
    int right = mid;
    int out = low;
    while (left < mid && right < high) {
      if (arr[left] <= arr[right]) {
        scratch[out] = arr[left];
        left++;
      } else {
        scratch[out] = arr[right];
        right++;
      }
      out++;
    }
    while (left < mid) {
      scratch[out++] = arr[left++];
    }
    while (right < high) {
      scratch[out++] = arr[right++];
    }
    System.arraycopy(scratch, low, arr, low, high - low);
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
