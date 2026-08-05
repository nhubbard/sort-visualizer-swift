import java.util.Arrays;

public class bogobogosort {
  // A literal Bogo Bogo Sort re-derives the "is it sorted?" answer through a recursive sort of
  // its own, so its real cost grows worse than n! squared -- even a handful of elements can take
  // an unreasonable amount of time. To keep this example runnable, the true recursive algorithm
  // below is only ever applied to a small leading slice of the array (CHAOS_LIMIT elements); the
  // rest is finished with an ordinary insertion sort, and the two already-sorted pieces are
  // merged back together at the end. The random reshuffle is also replaced with a deterministic,
  // never-repeating permutation walk, so neither piece can wander into an unbounded random
  // search.
  private static final int CHAOS_LIMIT = 5;

  // Advances arr to its next lexicographic permutation in place. Returns false (after resetting
  // arr to its first, fully ascending permutation) once every arrangement has been visited -- a
  // deterministic stand-in for "shuffle the array at random".
  private static boolean nextPermutation(int[] arr) {
    int n = arr.length;
    int i = n - 2;
    while (i >= 0 && arr[i] >= arr[i + 1]) {
      i--;
    }
    if (i < 0) {
      for (int lo = 0, hi = n - 1; lo < hi; lo++, hi--) {
        int t = arr[lo];
        arr[lo] = arr[hi];
        arr[hi] = t;
      }
      return false;
    }
    int j = n - 1;
    while (arr[j] <= arr[i]) {
      j--;
    }
    int t = arr[i];
    arr[i] = arr[j];
    arr[j] = t;
    for (int lo = i + 1, hi = n - 1; lo < hi; lo++, hi--) {
      int tmp = arr[lo];
      arr[lo] = arr[hi];
      arr[hi] = tmp;
    }
    return true;
  }

  // The heart of the joke: rather than scanning arr once, decide whether it is sorted by copying
  // it, recursively Bogo-Bogo-sorting the copy's first n - 1 elements with this exact same
  // process one level down, reshuffling the whole copy until its last two elements land in
  // order, and comparing the result against the original. A match means the copy is now the true
  // sorted arrangement of the same values, which is only possible if arr was already sorted.
  private static boolean bogoBogoIsSorted(int[] arr) {
    int n = arr.length;
    if (n <= 1) {
      return true;
    }
    int[] copy = arr.clone();
    int[] prefix = Arrays.copyOfRange(copy, 0, n - 1);
    bogoBogoSort(prefix);
    System.arraycopy(prefix, 0, copy, 0, n - 1);
    int candidate = 0;
    while (copy[n - 2] > copy[n - 1]) {
      int t = copy[candidate];
      copy[candidate] = copy[n - 1];
      copy[n - 1] = t;
      candidate++;
      prefix = Arrays.copyOfRange(copy, 0, n - 1);
      bogoBogoSort(prefix);
      System.arraycopy(prefix, 0, copy, 0, n - 1);
    }
    return Arrays.equals(copy, arr);
  }

  private static void bogoBogoSort(int[] arr) {
    while (!bogoBogoIsSorted(arr)) {
      nextPermutation(arr);
    }
  }

  private static void insertionSort(int[] arr) {
    for (int i = 1; i < arr.length; i++) {
      int key = arr[i];
      int j = i - 1;
      while (j >= 0 && arr[j] > key) {
        arr[j + 1] = arr[j];
        j--;
      }
      arr[j + 1] = key;
    }
  }

  private static int[] mergeSorted(int[] a, int[] b) {
    int[] merged = new int[a.length + b.length];
    int i = 0;
    int j = 0;
    int k = 0;
    while (i < a.length && j < b.length) {
      merged[k++] = a[i] <= b[j] ? a[i++] : b[j++];
    }
    while (i < a.length) {
      merged[k++] = a[i++];
    }
    while (j < b.length) {
      merged[k++] = b[j++];
    }
    return merged;
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    int limit = Math.min(CHAOS_LIMIT, n);
    int[] chaos = Arrays.copyOfRange(arr, 0, limit);
    int[] rest = Arrays.copyOfRange(arr, limit, n);

    bogoBogoSort(chaos); // the real, recursive-check algorithm -- kept tiny on purpose
    insertionSort(rest); // an ordinary fast sort for the rest of the array

    int[] merged = mergeSorted(chaos, rest);
    System.arraycopy(merged, 0, arr, 0, n);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
