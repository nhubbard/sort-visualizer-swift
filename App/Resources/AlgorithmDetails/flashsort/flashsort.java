import java.util.Arrays;

public class flashsort {
  private static int classify(int value, int minValue, double c) {
    return (int) ((value - minValue) * c) + 1;
  }

  private static void flashSort(int[] array) {
    int n = array.length;
    if (n == 0) {
      return;
    }

    int m = (int) (0.2 * n) + 2;

    int minValue = array[0];
    int maxValue = array[0];
    int maxIndex = 0;

    int i = 1;
    while (i < n - 1) {
      int small;
      int big;
      int bigIndex;
      if (array[i] < array[i + 1]) {
        small = array[i];
        big = array[i + 1];
        bigIndex = i + 1;
      } else {
        big = array[i];
        bigIndex = i;
        small = array[i + 1];
      }
      if (big > maxValue) {
        maxValue = big;
        maxIndex = bigIndex;
      }
      if (small < minValue) {
        minValue = small;
      }
      i += 2;
    }

    int last = array[n - 1];
    if (last < minValue) {
      minValue = last;
    } else if (last > maxValue) {
      maxValue = last;
      maxIndex = n - 1;
    }

    if (maxValue == minValue) {
      return;
    }

    @SuppressWarnings("checkstyle:localvariablename") // matches every other language's port
    int[] L = new int[m + 1];
    double c = (m - 1.0) / (maxValue - minValue);

    for (int h = 0; h < n; h++) {
      int k = classify(array[h], minValue, c);
      L[k] += 1;
    }

    for (int k = 2; k <= m; k++) {
      L[k] += L[k - 1];
    }

    int tmpSwap = array[maxIndex];
    array[maxIndex] = array[0];
    array[0] = tmpSwap;

    int j = 0;
    int k = m;
    int numMoves = 0;
    while (numMoves < n) {
      while (j >= L[k]) {
        j++;
        k = classify(array[j], minValue, c);
      }

      int evicted = array[j];
      while (j < L[k]) {
        k = classify(evicted, minValue, c);
        int location = L[k] - 1;
        int temp = array[location];
        array[location] = evicted;
        evicted = temp;
        L[k] -= 1;
        numMoves++;
      }
    }

    for (int idx = 1; idx < n; idx++) {
      int current = array[idx];
      int pos = idx - 1;
      while (pos >= 0 && array[pos] > current) {
        array[pos + 1] = array[pos];
        pos--;
      }
      array[pos + 1] = current;
    }
  }

  public static void sort(int[] arr) {
    flashSort(arr);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
