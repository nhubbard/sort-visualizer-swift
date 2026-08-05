import java.util.Arrays;

public final class minmaxheapsort {
  static int bitLength(int value) {
    int length = 0;
    while (value > 0) {
      value >>= 1;
      length++;
    }
    return length;
  }

  static boolean isMinLevel(int index) {
    return bitLength(index + 1) % 2 == 1;
  }

  static boolean betterThan(int a, int b, boolean minLevel) {
    return minLevel ? (a < b) : (a > b);
  }

  static void downheap(int[] arr, int start, int size) {
    int i = start;
    while (true) {
      boolean minLevel = isMinLevel(i);
      int left = 2 * i + 1;
      int right = 2 * i + 2;
      if (left >= size) {
        return;
      }
      int winner = left;
      if (right < size && betterThan(arr[right], arr[winner], minLevel)) {
        winner = right;
      }
      int base = 4 * i + 3;
      for (int offset = 0; offset < 4; offset++) {
        int gc = base + offset;
        if (gc < size && betterThan(arr[gc], arr[winner], minLevel)) {
          winner = gc;
        }
      }
      boolean isGrandchild = winner >= base;
      boolean extreme = betterThan(arr[winner], arr[i], minLevel);
      if (!isGrandchild) {
        if (extreme) {
          int temp = arr[i];
          arr[i] = arr[winner];
          arr[winner] = temp;
        }
        return;
      }
      if (extreme) {
        int temp = arr[i];
        arr[i] = arr[winner];
        arr[winner] = temp;
      } else {
        return;
      }
      int parent = (winner - 1) / 2;
      if (minLevel) {
        if (arr[winner] > arr[parent]) {
          int temp = arr[parent];
          arr[parent] = arr[winner];
          arr[winner] = temp;
        }
      } else {
        if (arr[winner] < arr[parent]) {
          int temp = arr[parent];
          arr[parent] = arr[winner];
          arr[winner] = temp;
        }
      }
      i = winner;
    }
  }

  static void heapify(int[] arr, int length) {
    for (int i = (length - 1) / 2; i >= 0; i--) {
      downheap(arr, i, length);
    }
  }

  static int storeMax(int[] arr, int heapSize) {
    if (heapSize <= 1) {
      return heapSize;
    }
    int imax = 1;
    if (heapSize > 2 && arr[2] > arr[1]) {
      imax = 2;
    }
    int last = heapSize - 1;
    int temp = arr[imax];
    arr[imax] = arr[last];
    arr[last] = temp;
    int newSize = last;
    if (imax < newSize) {
      downheap(arr, imax, newSize);
    }
    return newSize;
  }

  static void sort(int[] arr) {
    int n = arr.length;
    if (n <= 1) {
      return;
    }
    heapify(arr, n);
    int heapSize = n;
    for (int i = 0; i < n - 1; i++) {
      heapSize = storeMax(arr, heapSize);
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
