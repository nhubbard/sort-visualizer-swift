import java.util.Arrays;

public final class smoothsort {
  static final long[] LEONARDO = {
    1, 1, 3, 5, 9, 15, 25, 41, 67, 109, 177, 287, 465, 753, 1219, 1973, 3193, 5167, 8361, 13529,
    21891,
  };

  static int trailingZeroCount(long value) {
    long mask = value & ~1L;
    int trail = 0;
    while (mask != 0 && (mask & 1) == 0) {
      mask >>= 1;
      trail++;
    }
    return trail;
  }

  static void sift(int[] array, int pshiftIn, int headIn) {
    int pshift = pshiftIn;
    int head = headIn;
    int val = array[head];
    while (pshift > 1) {
      int rt = head - 1;
      int lf = head - 1 - (int) LEONARDO[pshift - 2];
      if (val >= array[lf] && val >= array[rt]) {
        break;
      }
      if (array[lf] >= array[rt]) {
        array[head] = array[lf];
        head = lf;
        pshift -= 1;
      } else {
        array[head] = array[rt];
        head = rt;
        pshift -= 2;
      }
    }
    array[head] = val;
  }

  static void trinkle(int[] array, long pIn, int pshiftIn, int headIn, boolean isTrustyIn) {
    long p = pIn;
    int pshift = pshiftIn;
    int head = headIn;
    boolean isTrusty = isTrustyIn;
    int val = array[head];
    while (p != 1) {
      int stepson = head - (int) LEONARDO[pshift];
      if (array[stepson] <= val) {
        break;
      }
      if (!isTrusty && pshift > 1) {
        int rt = head - 1;
        int lf = head - 1 - (int) LEONARDO[pshift - 2];
        if (array[rt] >= array[stepson] || array[lf] >= array[stepson]) {
          break;
        }
      }
      array[head] = array[stepson];
      head = stepson;
      int trail = trailingZeroCount(p);
      p >>= trail;
      pshift += trail;
      isTrusty = false;
    }
    if (!isTrusty) {
      array[head] = val;
      sift(array, pshift, head);
    }
  }

  static void sort(int[] array) {
    int n = array.length;
    if (n <= 1) {
      return;
    }

    int head = 0;
    long p = 1;
    int pshift = 1;
    int hi = n - 1;

    while (head < hi) {
      if ((p & 3) == 3) {
        sift(array, pshift, head);
        p >>= 2;
        pshift += 2;
      } else {
        if (LEONARDO[pshift - 1] >= hi - head) {
          trinkle(array, p, pshift, head, false);
        } else {
          sift(array, pshift, head);
        }
        if (pshift == 1) {
          p <<= 1;
          pshift -= 1;
        } else {
          p <<= (pshift - 1);
          pshift = 1;
        }
      }
      p |= 1;
      head += 1;
    }

    trinkle(array, p, pshift, head, false);
    while (pshift != 1 || p != 1) {
      if (pshift <= 1) {
        int trail = trailingZeroCount(p);
        p >>= trail;
        pshift += trail;
      } else {
        p <<= 2;
        p ^= 7;
        pshift -= 2;
        trinkle(array, p >> 1, pshift + 1, head - (int) LEONARDO[pshift] - 1, true);
        trinkle(array, p, pshift, head - 1, true);
      }
      head -= 1;
    }
  }

  public static void main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
