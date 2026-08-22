import java.util.Arrays;

public class stacklessamericanflagsort {
  static final int RADIX = 4;

  static int getDigit(int value, int place) {
    for (int p = 0; p < place; p++) {
      value /= RADIX;
    }
    return value % RADIX;
  }

  static int shift(int value, int places) {
    for (int p = 0; p < places; p++) {
      value /= RADIX;
    }
    return value;
  }

  // Turns the raw per-bucket counts already accumulated in `counts` into
  // starting offsets, then places every element in [start, end) by
  // following displacement cycles, one bucket at a time.
  static int distribute(int[] arr, int[] counts, int[] offsets, int start, int end, int place) {
    for (int i = 1; i < RADIX; i++) {
      counts[i] += counts[i - 1];
      offsets[i] = counts[i - 1];
    }

    for (int bucket = 0; bucket < RADIX - 1; bucket++) {
      int position = start + offsets[bucket];
      if (counts[bucket] > offsets[bucket]) {
        int held = arr[position];
        do {
          int digit = getDigit(held, place);
          counts[digit]--;
          int displaced = arr[start + counts[digit]];
          arr[start + counts[digit]] = held;
          held = displaced;
        } while (counts[bucket] > offsets[bucket]);
      }
    }

    int split = start + offsets[1];
    for (int i = 0; i < RADIX; i++) {
      counts[i] = 0;
      offsets[i] = 0;
    }
    return split;
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n < 2) {
      return;
    }

    int q = 0;
    int probe = RADIX;
    int maxValue = arr[0];
    for (int v : arr) {
      if (v > maxValue) {
        maxValue = v;
      }
    }
    while (probe <= maxValue) {
      q++;
      probe *= RADIX;
    }

    int[] counts = new int[RADIX];
    int[] offsets = new int[RADIX];

    // i/b track the bounds of whichever range is currently active, q the
    // digit place being distributed on, and m a counter that mirrors how
    // many bucket boundaries have already been walked at the current
    // depth, standing in for the call stack a recursive walk would need.
    int m = 0;
    int i = 0;
    int b = n;

    for (int j = i; j < b; j++) {
      counts[getDigit(arr[j], q)]++;
    }

    while (i < n) {
      int p = (b - i < 1) ? i : distribute(arr, counts, offsets, i, b, q);

      if (q == 0) {
        m += RADIX;
        int t = m / RADIX;
        while (t % RADIX == 0) {
          t /= RADIX;
          q++;
        }

        i = b;
        while (b < n && shift(arr[b], q + 1) == shift(m, q + 1)) {
          counts[getDigit(arr[b], q)]++;
          b++;
        }
      } else {
        b = p;
        q--;
        for (int j = i; j < b; j++) {
          counts[getDigit(arr[j], q)]++;
        }
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
