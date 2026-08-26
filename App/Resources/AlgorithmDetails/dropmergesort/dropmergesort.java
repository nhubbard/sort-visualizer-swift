import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class dropmergesort {
  static final int RECENCY = 8;
  static final int EARLY_OUT_TEST_AT = 4;
  static final double EARLY_OUT_DISORDER_FRACTION = 0.6;

  // A plain general-purpose sort for arr[lo..hi), used both as the early-out fallback and to
  // sort the leftover "dropped" elements before the final merge. Any decent O(n log n) sort
  // works here -- the algorithm doesn't depend on which one.
  static void quicksort(int[] arr, int lo, int hi) {
    if (hi - lo <= 1) {
      return;
    }
    int pivot = arr[lo + (hi - lo) / 2];
    List<Integer> less = new ArrayList<>();
    List<Integer> equal = new ArrayList<>();
    List<Integer> greater = new ArrayList<>();

    for (int i = lo; i < hi; i++) {
      if (arr[i] < pivot) {
        less.add(arr[i]);
      } else if (arr[i] > pivot) {
        greater.add(arr[i]);
      } else {
        equal.add(arr[i]);
      }
    }

    int[] lessArr = less.stream().mapToInt(Integer::intValue).toArray();
    int[] greaterArr = greater.stream().mapToInt(Integer::intValue).toArray();
    quicksort(lessArr, 0, lessArr.length);
    quicksort(greaterArr, 0, greaterArr.length);

    int k = lo;
    for (int value : lessArr) {
      arr[k++] = value;
    }
    for (int value : equal) {
      arr[k++] = value;
    }
    for (int value : greaterArr) {
      arr[k++] = value;
    }
  }

  public static void sort(int[] arr) {
    int length = arr.length;
    if (length < 2) {
      return;
    }

    List<Integer> dropped = new ArrayList<>();
    int numDroppedInARow = 0;
    int read = 0;
    int write = 0;
    int iteration = 0;
    int earlyOutStop = length / EARLY_OUT_TEST_AT;

    while (read < length) {
      iteration++;
      if (iteration == earlyOutStop && dropped.size() > read * EARLY_OUT_DISORDER_FRACTION) {
        // Too disordered for the adaptive approach to be worth it: flush what's been dropped so
        // far back into the array and fall back to a plain full sort.
        for (int value : dropped) {
          arr[write] = value;
          write++;
        }
        dropped.clear();
        quicksort(arr, 0, length);
        return;
      }

      if (write == 0 || arr[read] >= arr[write - 1]) {
        // In order -- keep it.
        arr[write] = arr[read];
        write++;
        read++;
        numDroppedInARow = 0;
      } else if (numDroppedInARow == 0 && write >= 2 && arr[read] >= arr[write - 2]) {
        // Quick undo: the element two back would have accepted this one just fine, so drop the
        // one right before it instead of the new element.
        dropped.add(arr[write - 1]);
        arr[write - 1] = arr[read];
        read++;
      } else if (numDroppedInARow < RECENCY) {
        dropped.add(arr[read]);
        read++;
        numDroppedInARow++;
      } else {
        // Accepting something `numDroppedInARow` elements back made every subsequent element
        // drop -- that accept was a mistake. Undo it, and any other recently accepted elements
        // bigger than the dropped run's maximum.
        dropped.subList(dropped.size() - numDroppedInARow, dropped.size()).clear();
        read -= numDroppedInARow;

        int numBacktracked = 1;
        write--;

        int maxOfDropped = arr[read];
        for (int i = read + 1; i <= read + numDroppedInARow; i++) {
          if (arr[i] > maxOfDropped) {
            maxOfDropped = arr[i];
          }
        }

        while (write >= 1 && maxOfDropped < arr[write - 1]) {
          write--;
          numBacktracked++;
        }

        for (int i = write; i < write + numBacktracked; i++) {
          dropped.add(arr[i]);
        }

        numDroppedInARow = 0;
      }
    }

    for (int offset = 0; offset < dropped.size(); offset++) {
      arr[write + offset] = dropped.get(offset);
    }

    quicksort(arr, write, length);

    // Copy the now-sorted dropped tail before the final backward merge starts overwriting
    // arr[write..] in place.
    int[] buffer = Arrays.copyOfRange(arr, write, write + dropped.size());

    int i = buffer.length - 1;
    int j = write - 1;
    int k = length - 1;

    while (i >= 0) {
      if (j < 0 || buffer[i] > arr[j]) {
        arr[k] = buffer[i];
        k--;
        i--;
      } else {
        arr[k] = arr[j];
        k--;
        j--;
      }
    }
  }

  public static void main(String[] args) {
    int[] array =
        new int[] {
          0, 1, 2, 3, 4, 9, 6, 7, 8, 5, 10, 11, 12, 13, 14, 15, 21, 17, 18, 19, 20, 16, 22, 23, 24,
          28, 26, 27, 25, 29
        };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
