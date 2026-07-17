import java.util.Arrays;

public class simplifiedlibrarysort {
  private static int binarySearch(int arr[], int item, int start, int end) {
    int lo = start;
    int hi = end;
    while (lo < hi) {
      int mid = lo + (hi - lo) / 2;
      if (item < arr[mid]) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    return lo;
  }

  private static void binaryInsertionSort(int arr[], int start, int end) {
    for (int i = start + 1; i < end; i++) {
      int item = arr[i];
      int pos = binarySearch(arr, item, start, i);
      int j = i;
      while (j > pos) {
        arr[j] = arr[j - 1];
        j--;
      }
      arr[pos] = item;
    }
  }

  private static void rebalance(int arr[], int temp[], int counts[], int locations[], int spineSize, int batchEnd) {
    for (int i = 0; i < spineSize; i++) {
      counts[i + 1] = counts[i + 1] + counts[i] + 1;
    }

    int k = 0;
    for (int i = spineSize; i < batchEnd; i++) {
      int gap = locations[k];
      int position = counts[gap];
      temp[position] = arr[i];
      counts[gap] = position + 1;
      k++;
    }

    for (int i = 0; i < spineSize; i++) {
      int position = counts[i];
      temp[position] = arr[i];
      counts[i] = position + 1;
    }

    for (int i = 0; i < batchEnd; i++) {
      arr[i] = temp[i];
    }

    binaryInsertionSort(arr, 0, counts[0] - 1);
    for (int i = 0; i < spineSize - 1; i++) {
      binaryInsertionSort(arr, counts[i], counts[i + 1] - 1);
    }
    binaryInsertionSort(arr, counts[spineSize - 1], counts[spineSize]);

    for (int i = 0; i < spineSize + 2; i++) {
      counts[i] = 0;
    }
  }

  private static void librarySort(int arr[]) {
    int n = arr.length;
    if (n < 2) {
      return;
    }

    int rebalanceFactor = 2;
    int spineSize = 1;
    binaryInsertionSort(arr, 0, spineSize);

    int maxLevel = spineSize;
    while (maxLevel * rebalanceFactor < n) {
      maxLevel *= rebalanceFactor;
    }

    int[] temp = new int[n];
    int[] counts = new int[maxLevel + 2];
    int[] locations = new int[n];

    int i = spineSize;
    int k = 0;
    while (i < n) {
      if (rebalanceFactor * spineSize == i) {
        rebalance(arr, temp, counts, locations, spineSize, i);
        spineSize = i;
        k = 0;
      }
      int gap = binarySearch(arr, arr[i], 0, spineSize);
      counts[gap + 1]++;
      locations[k] = gap;
      k++;
      i++;
    }
    rebalance(arr, temp, counts, locations, spineSize, n);
  }

  public static void sort(int arr[]) {
    librarySort(arr);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
