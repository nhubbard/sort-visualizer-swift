import java.util.Arrays;

public class weavemergesort {
  private static void multiSwap(int[] arr, int pos, int to) {
    if (to - pos > 0) {
      for (int i = pos; i < to; i++) {
        int tmp = arr[i];
        arr[i] = arr[i + 1];
        arr[i + 1] = tmp;
      }
    } else {
      for (int i = pos; i > to; i--) {
        int tmp = arr[i];
        arr[i] = arr[i - 1];
        arr[i - 1] = tmp;
      }
    }
  }

  private static void weaveInsert(int[] arr, int start, int end) {
    for (int j = start; j < end; j++) {
      int pos = j;
      while (pos > start && arr[pos] <= arr[pos - 1]) {
        int tmp = arr[pos];
        arr[pos] = arr[pos - 1];
        arr[pos - 1] = tmp;
        pos--;
      }
    }
  }

  private static void weaveMerge(int[] arr, int min, int max, int mid) {
    int target = mid - min;
    for (int i = 1; i <= target; i++) {
      multiSwap(arr, mid + i, min + (i * 2) - 1);
    }
    weaveInsert(arr, min, max + 1);
  }

  private static void weaveMergeSort(int[] arr, int min, int max) {
    if (max - min == 0) {
      return;
    } else if (max - min == 1) {
      if (arr[min] > arr[max]) {
        int tmp = arr[min];
        arr[min] = arr[max];
        arr[max] = tmp;
      }
    } else {
      int mid = (min + max) / 2;
      weaveMergeSort(arr, min, mid);
      weaveMergeSort(arr, mid + 1, max);
      weaveMerge(arr, min, max, mid);
    }
  }

  public static void sort(int[] arr) {
    if (arr.length > 1) {
      weaveMergeSort(arr, 0, arr.length - 1);
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
