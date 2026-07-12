import java.util.Arrays;

public class inplacemergesort {
  private static void push(int arr[], int low, int high) {
    for (int i = low; i < high; i++) {
      if (arr[i] > arr[i + 1]) {
        int temp = arr[i];
        arr[i] = arr[i + 1];
        arr[i + 1] = temp;
      }
    }
  }

  private static void merge(int arr[], int low, int high, int mid) {
    int i = low;
    while (i <= mid) {
      if (arr[i] > arr[mid + 1]) {
        int temp = arr[i];
        arr[i] = arr[mid + 1];
        arr[mid + 1] = temp;
        push(arr, mid + 1, high);
      }
      i++;
    }
  }

  private static void mergeSort(int arr[], int low, int high) {
    if (high - low == 0) {
      return;
    } else if (high - low == 1) {
      if (arr[low] > arr[high]) {
        int temp = arr[low];
        arr[low] = arr[high];
        arr[high] = temp;
      }
    } else {
      int mid = (low + high) / 2;
      mergeSort(arr, low, mid);
      mergeSort(arr, mid + 1, high);
      merge(arr, low, high, mid);
    }
  }

  public static void sort(int arr[]) {
    if (arr.length >= 2) {
      mergeSort(arr, 0, arr.length - 1);
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
