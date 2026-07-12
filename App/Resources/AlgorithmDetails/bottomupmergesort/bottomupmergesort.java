import java.util.Arrays;

public class bottomupmergesort {
  private static void merge(int[] arr, int low, int mid, int high) {
    int[] left = Arrays.copyOfRange(arr, low, mid);
    int[] right = Arrays.copyOfRange(arr, mid, high);
    int i = 0, j = 0, k = low;
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

  public static void sort(int arr[]) {
    int n = arr.length;
    for (int width = 1; width < n; width *= 2) {
      for (int low = 0; low < n; low += 2 * width) {
        int mid = Math.min(low + width, n);
        int high = Math.min(low + 2 * width, n);
        if (mid < high) {
          merge(arr, low, mid, high);
        }
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
