import java.util.Arrays;

public class doubleinsertionsort {
  private static void doubleInsertionSort(int arr[], int start, int end) {
    int left = start + (end - start) / 2 - 1;
    int right = left + 1;
    if (arr[left] > arr[right]) {
      int temp = arr[left];
      arr[left] = arr[right];
      arr[right] = temp;
    }
    left--;
    right++;

    while (left >= start && right < end) {
      if (arr[left] > arr[right]) {
        int leftItem = arr[right];
        int rightItem = arr[left];

        int pos = left + 1;
        while (pos <= right && arr[pos] <= leftItem) {
          arr[pos - 1] = arr[pos];
          pos++;
        }
        arr[pos - 1] = leftItem;

        pos = right - 1;
        while (pos >= left && arr[pos] >= rightItem) {
          arr[pos + 1] = arr[pos];
          pos--;
        }
        arr[pos + 1] = rightItem;
      } else {
        int leftItem = arr[left];
        int rightItem = arr[right];

        int pos = left + 1;
        while (arr[pos] < leftItem) {
          arr[pos - 1] = arr[pos];
          pos++;
        }
        arr[pos - 1] = leftItem;

        pos = right - 1;
        while (arr[pos] > rightItem) {
          arr[pos + 1] = arr[pos];
          pos--;
        }
        arr[pos + 1] = rightItem;
      }

      left--;
      right++;
    }

    if (right < end) {
      int pos = right - 1;
      int current = arr[right];
      while (pos >= start && arr[pos] > current) {
        arr[pos + 1] = arr[pos];
        pos--;
      }
      arr[pos + 1] = current;
    }
  }

  public static void sort(int arr[]) {
    if (arr.length > 1) {
      doubleInsertionSort(arr, 0, arr.length);
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
