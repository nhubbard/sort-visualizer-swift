import java.util.Arrays;

public class optimizeddualpivotquicksort {
  static final int INSERTION_THRESHOLD = 24;

  // Once a range's "between the pivots" middle partition holds more than this fraction of the
  // range, it's worth pausing to scan out any elements that exactly equal one of the two
  // pivots before recursing into what's left.
  static final int EQUAL_ELEMENTS_MIN_FRACTION = 4;

  // Sorts arr[low..high] in place (both bounds inclusive).
  static void insertionSort(int[] arr, int low, int high) {
    for (int i = low + 1; i <= high; i++) {
      int key = arr[i];
      int j = i - 1;
      while (j >= low && arr[j] > key) {
        arr[j + 1] = arr[j];
        j--;
      }
      arr[j + 1] = key;
    }
  }

  // arr[low..high] holds only values in the closed range [pivot1, pivot2]. In a single scan,
  // moves every element equal to pivot1 to the front and every element equal to pivot2 to the
  // back -- a Dutch-national-flag-style three-way partition, generalized to two specific
  // target values instead of "less than/greater than a pivot". Returns {low, high}: the
  // inclusive bounds of what's left strictly between the two pivots.
  static int[] movePivotDuplicatesOut(int[] arr, int low, int high, int pivot1, int pivot2) {
    int writeLow = low;
    int read = low;
    int writeHigh = high;
    while (read <= writeHigh) {
      if (arr[read] == pivot1) {
        int t = arr[read];
        arr[read] = arr[writeLow];
        arr[writeLow] = t;
        writeLow++;
        read++;
      } else if (arr[read] == pivot2) {
        int t = arr[read];
        arr[read] = arr[writeHigh];
        arr[writeHigh] = t;
        writeHigh--;
      } else {
        read++;
      }
    }
    return new int[] {writeLow, writeHigh};
  }

  // Sorts arr[low..high] in place (both bounds inclusive).
  static void optimizedDualPivotQuickSort(int[] arr, int low, int high) {
    int size = high - low + 1;
    if (size <= INSERTION_THRESHOLD) {
      if (size > 1) {
        insertionSort(arr, low, high);
      }
      return;
    }

    // Sample two candidates roughly a third of the way in from each end and seed the two
    // pivots from them, smaller one first.
    int third = size / 3;
    int pivot1Index = low + third;
    int pivot2Index = high - third;
    if (arr[pivot1Index] > arr[pivot2Index]) {
      int t = arr[pivot1Index];
      arr[pivot1Index] = arr[pivot2Index];
      arr[pivot2Index] = t;
    }
    int t1 = arr[low];
    arr[low] = arr[pivot1Index];
    arr[pivot1Index] = t1;
    int t2 = arr[high];
    arr[high] = arr[pivot2Index];
    arr[pivot2Index] = t2;
    int pivot1 = arr[low];
    int pivot2 = arr[high];

    // Single left-to-right scan splitting the interior into three regions: less than pivot1,
    // between the two pivots, and greater than pivot2.
    int less = low + 1;
    int great = high - 1;
    int k = less;
    while (k <= great) {
      if (arr[k] < pivot1) {
        int t = arr[k];
        arr[k] = arr[less];
        arr[less] = t;
        less++;
      } else if (arr[k] > pivot2) {
        while (k < great && arr[great] > pivot2) {
          great--;
        }
        int t = arr[k];
        arr[k] = arr[great];
        arr[great] = t;
        great--;
        if (arr[k] < pivot1) {
          int t3 = arr[k];
          arr[k] = arr[less];
          arr[less] = t3;
          less++;
        }
      }
      k++;
    }

    // Drop the two pivots into place at the boundaries of their regions.
    less--;
    great++;
    int t3 = arr[low];
    arr[low] = arr[less];
    arr[less] = t3;
    int t4 = arr[high];
    arr[high] = arr[great];
    arr[great] = t4;

    // arr[low..less-1] < pivot1, arr[less] == pivot1, arr[less+1..great-1] is the middle
    // region, arr[great] == pivot2, arr[great+1..high] > pivot2.
    optimizedDualPivotQuickSort(arr, low, less - 1);
    optimizedDualPivotQuickSort(arr, great + 1, high);

    int middleLow = less + 1;
    int middleHigh = great - 1;

    if (pivot1 != pivot2 && middleHigh >= middleLow) {
      int middleSize = middleHigh - middleLow + 1;
      // Equal-elements optimization: a middle region this large is usually full of values
      // tied to one pivot or the other, which would otherwise get pointlessly
      // re-partitioned by the recursive call below. Shrink it first by scanning out the
      // exact duplicates. They're already correctly positioned relative to the low and high
      // regions -- every pivot1 duplicate is >= everything already sorted into the low
      // region, and every pivot2 duplicate is <= everything already sorted into the high
      // region -- so neither of those two regions needs to be touched again.
      if (middleSize > size / EQUAL_ELEMENTS_MIN_FRACTION) {
        int[] bounds = movePivotDuplicatesOut(arr, middleLow, middleHigh, pivot1, pivot2);
        middleLow = bounds[0];
        middleHigh = bounds[1];
      }
    }

    if (pivot1 != pivot2 && middleHigh >= middleLow) {
      optimizedDualPivotQuickSort(arr, middleLow, middleHigh);
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n < 2) {
      return;
    }
    optimizedDualPivotQuickSort(arr, 0, n - 1);
  }

  public static void main(String[] args) {
    int[] array =
        new int[] {
          55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79, 21, 88, 5, 51, 66, 29, 44,
          12, 78, 33, 91, 6, 58, 12
        };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
