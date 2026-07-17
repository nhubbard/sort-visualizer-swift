import java.util.Arrays;

public class dualpivotquicksort {
  private static int[] partition(int arr[], int low, int high) {
    if (arr[low] > arr[high]) {
      int t = arr[low];
      arr[low] = arr[high];
      arr[high] = t;
    }
    int j = low + 1;
    int g = high - 1;
    int k = low + 1;
    int p = arr[low];
    int q = arr[high];
    while (k <= g) {
      if (arr[k] < p) {
        int t = arr[k];
        arr[k] = arr[j];
        arr[j] = t;
        j++;
      } else if (arr[k] >= q) {
        while (arr[g] > q && k < g) {
          g--;
        }
        int t = arr[k];
        arr[k] = arr[g];
        arr[g] = t;
        g--;
        if (arr[k] < p) {
          int t2 = arr[k];
          arr[k] = arr[j];
          arr[j] = t2;
          j++;
        }
      }
      k++;
    }
    j--;
    g++;
    int t = arr[low];
    arr[low] = arr[j];
    arr[j] = t;
    int t2 = arr[high];
    arr[high] = arr[g];
    arr[g] = t2;
    return new int[]{j, g};
  }

  public static void dualPivotQuickSort(int arr[], int low, int high) {
    if (low < high) {
      int[] pivots = partition(arr, low, high);
      dualPivotQuickSort(arr, low, pivots[0] - 1);
      dualPivotQuickSort(arr, pivots[0] + 1, pivots[1] - 1);
      dualPivotQuickSort(arr, pivots[1] + 1, high);
    }
  }

  public static void sort(int arr[]) {
    dualPivotQuickSort(arr, 0, arr.length - 1);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
