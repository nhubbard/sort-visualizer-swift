import java.util.Arrays;

public class staticsort {
  private static int[] findMinMax(int[] array, int a, int b) {
    int minValue = array[a];
    int maxValue = array[a];
    for (int i = a + 1; i < b; i++) {
      if (array[i] < minValue) {
        minValue = array[i];
      } else if (array[i] > maxValue) {
        maxValue = array[i];
      }
    }
    return new int[] {minValue, maxValue};
  }

  private static void insertionSortRange(int[] array, int s, int e) {
    for (int i = s + 1; i < e; i++) {
      int j = i;
      while (j > s && array[j - 1] > array[j]) {
        int tmp = array[j - 1];
        array[j - 1] = array[j];
        array[j] = tmp;
        j--;
      }
    }
  }

  private static void siftDown(int[] array, int s, int root, int size) {
    while (true) {
      int largest = root;
      int left = 2 * root + 1;
      int right = 2 * root + 2;
      if (left < size && array[s + largest] < array[s + left]) {
        largest = left;
      }
      if (right < size && array[s + largest] < array[s + right]) {
        largest = right;
      }
      if (largest == root) {
        break;
      }
      int tmp = array[s + root];
      array[s + root] = array[s + largest];
      array[s + largest] = tmp;
      root = largest;
    }
  }

  private static void heapSortRange(int[] array, int s, int e) {
    int size = e - s;
    if (size <= 1) {
      return;
    }
    int i = size / 2 - 1;
    while (i >= 0) {
      siftDown(array, s, i, size);
      i--;
    }
    int end = size - 1;
    while (end > 0) {
      int tmp = array[s];
      array[s] = array[s + end];
      array[s + end] = tmp;
      siftDown(array, s, 0, end);
      end--;
    }
  }

  private static int classify(int value, int minValue, double c) {
    return (int) ((value - minValue) * c);
  }

  private static void staticSort(int[] array, int a, int b) {
    int[] minMax = findMinMax(array, a, b);
    int minValue = minMax[0];
    int maxValue = minMax[1];
    int auxLen = b - a;
    int[] count = new int[auxLen + 1];
    int[] offset = new int[auxLen + 1];
    double c = (double) auxLen / (maxValue - minValue + 1);

    for (int i = a; i < b; i++) {
      int idx = classify(array[i], minValue, c);
      count[idx] += 1;
    }

    offset[0] = a;
    for (int i = 1; i < auxLen; i++) {
      offset[i] = count[i - 1] + offset[i - 1];
    }

    for (int v = 0; v < auxLen; v++) {
      while (count[v] > 0) {
        int origin = offset[v];
        int from = origin;
        int num = array[from];
        array[from] = -1;
        do {
          int idx = classify(num, minValue, c);
          int to = offset[idx];
          offset[idx] += 1;
          count[idx] -= 1;
          int temp = array[to];
          array[to] = num;
          num = temp;
          from = to;
        } while (from != origin);
      }
    }

    for (int i = 0; i < auxLen; i++) {
      int s = (i > 1) ? offset[i - 1] : a;
      int e = offset[i];
      if (e - s <= 1) {
        continue;
      }
      if (e - s > 16) {
        heapSortRange(array, s, e);
      } else {
        insertionSortRange(array, s, e);
      }
    }
  }

  public static void sort(int[] arr) {
    if (arr.length > 1) {
      staticSort(arr, 0, arr.length);
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
