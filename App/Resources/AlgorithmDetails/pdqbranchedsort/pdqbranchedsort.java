import java.util.Arrays;

public class pdqbranchedsort {
  private static final int INSERT_SORT_THRESHOLD = 24;
  private static final int NINTHER_THRESHOLD = 128;
  private static final int PARTIAL_INSERT_SORT_LIMIT = 8;

  private static void swap(int[] arr, int a, int b) {
    int t = arr[a];
    arr[a] = arr[b];
    arr[b] = t;
  }

  private static int pdqLog(int n) {
    int log = 0;
    while ((n >>= 1) != 0) {
      log++;
    }
    return log;
  }

  private static void insertSort(int[] arr, int begin, int end) {
    for (int cur = begin + 1; cur < end; cur++) {
      if (arr[cur] < arr[cur - 1]) {
        int tmp = arr[cur];
        int sift = cur;
        int siftMinusOne = cur - 1;
        do {
          arr[sift--] = arr[siftMinusOne--];
        } while (sift != begin && tmp < arr[siftMinusOne]);
        arr[sift] = tmp;
      }
    }
  }

  private static void unguardInsertSort(int[] arr, int begin, int end) {
    for (int cur = begin + 1; cur < end; cur++) {
      if (arr[cur] < arr[cur - 1]) {
        int tmp = arr[cur];
        int sift = cur;
        int siftMinusOne = cur - 1;
        do {
          arr[sift--] = arr[siftMinusOne--];
        } while (tmp < arr[siftMinusOne]);
        arr[sift] = tmp;
      }
    }
  }

  private static boolean partialInsertSort(int[] arr, int begin, int end) {
    int limit = 0;
    for (int cur = begin + 1; cur < end; cur++) {
      if (limit > PARTIAL_INSERT_SORT_LIMIT) {
        return false;
      }
      if (arr[cur] < arr[cur - 1]) {
        int tmp = arr[cur];
        int sift = cur;
        int siftMinusOne = cur - 1;
        do {
          arr[sift--] = arr[siftMinusOne--];
        } while (sift != begin && tmp < arr[siftMinusOne]);
        arr[sift] = tmp;
        limit += cur - sift;
      }
    }
    return true;
  }

  private static void sortTwo(int[] arr, int a, int b) {
    if (arr[b] < arr[a]) {
      swap(arr, a, b);
    }
  }

  private static void sortThree(int[] arr, int a, int b, int c) {
    sortTwo(arr, a, b);
    sortTwo(arr, b, c);
    sortTwo(arr, a, b);
  }

  private static final class PDQPair {
    final int pivotPos;
    final boolean alreadyParted;

    PDQPair(int pivotPos, boolean alreadyParted) {
      this.pivotPos = pivotPos;
      this.alreadyParted = alreadyParted;
    }
  }

  private static PDQPair partRight(int[] arr, int begin, int end) {
    int pivot = arr[begin];
    int first = begin;
    int last = end;

    first++;
    while (arr[first] < pivot) {
      first++;
    }

    if (first - 1 == begin) {
      last--;
      while (first < last && !(arr[last] < pivot)) {
        last--;
      }
    } else {
      last--;
      while (!(arr[last] < pivot)) {
        last--;
      }
    }

    boolean alreadyParted = first >= last;
    while (first < last) {
      swap(arr, first, last);
      first++;
      while (arr[first] < pivot) {
        first++;
      }
      last--;
      while (!(arr[last] < pivot)) {
        last--;
      }
    }

    int pivotPos = first - 1;
    arr[begin] = arr[pivotPos];
    arr[pivotPos] = pivot;

    return new PDQPair(pivotPos, alreadyParted);
  }

  private static int partLeft(int[] arr, int begin, int end) {
    int pivot = arr[begin];
    int first = begin;
    int last = end;

    last--;
    while (pivot < arr[last]) {
      last--;
    }

    if (last + 1 == end) {
      first++;
      while (first < last && !(pivot < arr[first])) {
        first++;
      }
    } else {
      first++;
      while (!(pivot < arr[first])) {
        first++;
      }
    }

    while (first < last) {
      swap(arr, first, last);
      last--;
      while (pivot < arr[last]) {
        last--;
      }
      first++;
      while (!(pivot < arr[first])) {
        first++;
      }
    }

    int pivotPos = last;
    arr[begin] = arr[pivotPos];
    arr[pivotPos] = pivot;
    return pivotPos;
  }

  private static void siftDown(int[] arr, int begin, int root, int size) {
    while (true) {
      int child = 2 * root + 1;
      if (child >= size) {
        break;
      }
      if (child + 1 < size && arr[begin + child] < arr[begin + child + 1]) {
        child++;
      }
      if (arr[begin + root] < arr[begin + child]) {
        swap(arr, begin + root, begin + child);
        root = child;
      } else {
        break;
      }
    }
  }

  private static void heapSort(int[] arr, int begin, int end) {
    int n = end - begin;
    for (int i = n / 2 - 1; i >= 0; i--) {
      siftDown(arr, begin, i, n);
    }
    for (int i = n - 1; i > 0; i--) {
      swap(arr, begin, begin + i);
      siftDown(arr, begin, 0, i);
    }
  }

  private static void pdqLoop(int[] arr, int begin, int end, int badAllowed) {
    boolean leftmost = true;
    while (true) {
      int size = end - begin;

      if (size < INSERT_SORT_THRESHOLD) {
        if (leftmost) {
          insertSort(arr, begin, end);
        } else {
          unguardInsertSort(arr, begin, end);
        }
        return;
      }

      int halfSize = size / 2;
      if (size > NINTHER_THRESHOLD) {
        sortThree(arr, begin, begin + halfSize, end - 1);
        sortThree(arr, begin + 1, begin + halfSize - 1, end - 2);
        sortThree(arr, begin + 2, begin + halfSize + 1, end - 3);
        sortThree(arr, begin + halfSize - 1, begin + halfSize, begin + halfSize + 1);
        swap(arr, begin, begin + halfSize);
      } else {
        sortThree(arr, begin + halfSize, begin, end - 1);
      }

      if (!leftmost && !(arr[begin - 1] < arr[begin])) {
        begin = partLeft(arr, begin, end) + 1;
        continue;
      }

      PDQPair partResult = partRight(arr, begin, end);
      int pivotPos = partResult.pivotPos;
      boolean alreadyParted = partResult.alreadyParted;

      int leftSize = pivotPos - begin;
      int rightSize = end - (pivotPos + 1);
      boolean highUnbalance = leftSize < size / 8 || rightSize < size / 8;

      if (highUnbalance) {
        if (--badAllowed == 0) {
          heapSort(arr, begin, end);
          return;
        }

        if (leftSize >= INSERT_SORT_THRESHOLD) {
          swap(arr, begin, begin + leftSize / 4);
          swap(arr, pivotPos - 1, pivotPos - leftSize / 4);
          if (leftSize > NINTHER_THRESHOLD) {
            swap(arr, begin + 1, begin + (leftSize / 4 + 1));
            swap(arr, begin + 2, begin + (leftSize / 4 + 2));
            swap(arr, pivotPos - 2, pivotPos - (leftSize / 4 + 1));
            swap(arr, pivotPos - 3, pivotPos - (leftSize / 4 + 2));
          }
        }

        if (rightSize >= INSERT_SORT_THRESHOLD) {
          swap(arr, pivotPos + 1, pivotPos + (1 + rightSize / 4));
          swap(arr, end - 1, end - rightSize / 4);
          if (rightSize > NINTHER_THRESHOLD) {
            swap(arr, pivotPos + 2, pivotPos + (2 + rightSize / 4));
            swap(arr, pivotPos + 3, pivotPos + (3 + rightSize / 4));
            swap(arr, end - 2, end - (1 + rightSize / 4));
            swap(arr, end - 3, end - (2 + rightSize / 4));
          }
        }
      } else {
        if (alreadyParted
            && partialInsertSort(arr, begin, pivotPos)
            && partialInsertSort(arr, pivotPos + 1, end)) {
          return;
        }
      }

      pdqLoop(arr, begin, pivotPos, badAllowed);
      begin = pivotPos + 1;
      leftmost = false;
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n < 2) {
      return;
    }
    pdqLoop(arr, 0, n, pdqLog(n));
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
