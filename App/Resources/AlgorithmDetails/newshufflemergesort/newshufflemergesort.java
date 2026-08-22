import java.util.Arrays;

public class newshufflemergesort {
  private static void multiSwap(int[] arr, int i, int j, int length) {
    for (int k = 0; k < length; k++) {
      int t = arr[i + k];
      arr[i + k] = arr[j + k];
      arr[j + k] = t;
    }
  }

  private static void rotate(int[] arr, int mid, int leftLen, int rightLen) {
    while (leftLen > 0 && rightLen > 0) {
      if (leftLen > rightLen) {
        multiSwap(arr, mid - rightLen, mid, rightLen);
        mid -= rightLen;
        leftLen -= rightLen;
      } else {
        multiSwap(arr, mid - leftLen, mid, leftLen);
        mid += leftLen;
        rightLen -= leftLen;
      }
    }
  }

  // Perfect-shuffles a chunk of `size - 1` elements by following the cycles of i -> i*2 mod size.
  private static void shuffleBlock(int[] arr, int start, int size) {
    int i = 1;
    while (i < size) {
      int val = arr[start + i - 1];
      int j = (i * 2) % size;
      while (j != i) {
        int nextVal = arr[start + j - 1];
        arr[start + j - 1] = val;
        val = nextVal;
        j = (j * 2) % size;
      }
      arr[start + i - 1] = val;
      i *= 3;
    }
  }

  // A single riffle shuffle only closes into clean cycles at power-of-three sizes, so shuffling
  // happens in power-of-three chunks, rotating the next chunk's tail into place before each one.
  private static void shuffle(int[] arr, int start, int end) {
    while (end - start > 1) {
      int half = (end - start) / 2;
      int chunk = 1;
      while (chunk * 3 - 1 <= 2 * half) {
        chunk *= 3;
      }
      int tail = (chunk - 1) / 2;
      rotate(arr, start + half, half - tail, tail);
      shuffleBlock(arr, start, chunk);
      start += chunk - 1;
    }
  }

  private static void rotateShuffledEqual(int[] arr, int i, int j, int size) {
    for (int k = 0; k < size; k += 2) {
      int t = arr[i + k];
      arr[i + k] = arr[j + k];
      arr[j + k] = t;
    }
  }

  private static void rotateShuffled(int[] arr, int mid, int leftLen, int rightLen) {
    while (leftLen > 0 && rightLen > 0) {
      if (leftLen > rightLen) {
        rotateShuffledEqual(arr, mid - rightLen, mid, rightLen);
        mid -= rightLen;
        leftLen -= rightLen;
      } else {
        rotateShuffledEqual(arr, mid - leftLen, mid, leftLen);
        mid += leftLen;
        rightLen -= leftLen;
      }
    }
  }

  private static void rotateShuffledOuter(int[] arr, int mid, int leftLen, int rightLen) {
    if (leftLen > rightLen) {
      rotateShuffledEqual(arr, mid - rightLen, mid + 1, rightLen);
      mid -= rightLen;
      leftLen -= rightLen;
      rotateShuffled(arr, mid, leftLen, rightLen);
    } else {
      rotateShuffledEqual(arr, mid - leftLen, mid + 1, leftLen);
      mid += leftLen + 1;
      rightLen -= leftLen;
      rotateShuffled(arr, mid, leftLen, rightLen);
    }
  }

  // The inverse of shuffleBlock: walks the same cycles, writing each value one step backward.
  private static void unshuffleBlock(int[] arr, int start, int size) {
    int i = 1;
    while (i < size) {
      int prev = i;
      int val = arr[start + i - 1];
      int j = (i * 2) % size;
      while (j != i) {
        arr[start + prev - 1] = arr[start + j - 1];
        prev = j;
        j = (j * 2) % size;
      }
      arr[start + prev - 1] = val;
      i *= 3;
    }
  }

  private static void unshuffle(int[] arr, int start, int end) {
    while (end - start > 1) {
      int half = (end - start) / 2;
      int chunk = 1;
      while (chunk * 3 - 1 <= 2 * half) {
        chunk *= 3;
      }
      int tail = (chunk - 1) / 2;
      rotateShuffledOuter(arr, start + 2 * tail, 2 * tail, 2 * half - 2 * tail);
      unshuffleBlock(arr, start, chunk);
      start += chunk - 1;
    }
  }

  private static int compare3(int[] arr, int i, int j) {
    if (arr[i] < arr[j]) {
      return -1;
    }
    return arr[i] == arr[j] ? 0 : 1;
  }

  // Scans the shuffled (interleaved) range one adjacent pair at a time. A pair already in order
  // just advances the scan; a stretch of same-side elements gets un-shuffled back into two short
  // plain runs and rotated into its final position.
  private static void mergeUp(int[] arr, int start, int end, boolean fromLeft) {
    int i = start;
    int j = i + 1;
    while (j < end) {
      int cmp = compare3(arr, i, j);
      if (cmp == -1 || (!fromLeft && cmp == 0)) {
        i++;
        if (i == j) {
          j++;
          fromLeft = !fromLeft;
        }
      } else if (end - j == 1) {
        rotate(arr, j, j - i, 1);
        break;
      } else {
        int run = 0;
        if (fromLeft) {
          while (j + 2 * run < end && compare3(arr, j + 2 * run, i) != 1) {
            run++;
          }
        } else {
          while (j + 2 * run < end && compare3(arr, j + 2 * run, i) == -1) {
            run++;
          }
        }
        j--;
        unshuffle(arr, j, j + 2 * run);
        rotate(arr, j, j - i, run);
        i += run + 1;
        j += 2 * run + 1;
      }
    }
  }

  private static void merge(int[] arr, int start, int mid, int end) {
    if (mid - start <= end - mid) {
      shuffle(arr, start, end);
      mergeUp(arr, start, end, true);
    } else {
      shuffle(arr, start + 1, end);
      mergeUp(arr, start, end, false);
    }
  }

  private static int ceilPow2(int x) {
    x -= 1;
    for (int shift = 16; shift > 0; shift >>= 1) {
      x |= x >> shift;
    }
    return x + 1;
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n < 2) {
      return;
    }

    int subarrayCount = ceilPow2(n);
    while (subarrayCount > 1) {
      int i = 0;
      while (i < subarrayCount) {
        int lo = n * i / subarrayCount;
        int mid = n * (i + 1) / subarrayCount;
        int hi = n * (i + 2) / subarrayCount;
        merge(arr, lo, mid, hi);
        i += 2;
      }
      subarrayCount >>= 1;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
