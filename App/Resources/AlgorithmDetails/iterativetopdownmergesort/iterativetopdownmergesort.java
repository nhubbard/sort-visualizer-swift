import java.util.Arrays;

public class iterativetopdownmergesort {
  private static void merge(int[] arr, int low, int mid, int high) {
    int[] left = Arrays.copyOfRange(arr, low, mid);
    int[] right = Arrays.copyOfRange(arr, mid, high);
    int i = 0;
    int j = 0;
    int k = low;
    while (i < left.length && j < right.length) {
      if (left[i] <= right[j]) {
        arr[k] = left[i];
        i++;
      } else {
        arr[k] = right[j];
        j++;
      }
      k++;
    }
    while (i < left.length) {
      arr[k] = left[i];
      i++;
      k++;
    }
    while (j < right.length) {
      arr[k] = right[j];
      j++;
      k++;
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    int subarrayCount = 1;
    while (subarrayCount < n) {
      subarrayCount *= 2;
    }

    while (subarrayCount > 1) {
      for (int i = 0; i < subarrayCount; i += 2) {
        int low = n * i / subarrayCount;
        int mid = n * (i + 1) / subarrayCount;
        int high = n * (i + 2) / subarrayCount;
        merge(arr, low, mid, high);
      }
      subarrayCount /= 2;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
