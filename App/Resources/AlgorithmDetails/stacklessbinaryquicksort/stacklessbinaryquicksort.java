import java.util.Arrays;

public class stacklessbinaryquicksort {
  private static int mostSignificantBit(int value) {
    if (value == 0) {
      return -1;
    }
    int bit = 0;
    while ((value >> (bit + 1)) != 0) {
      bit++;
    }
    return bit;
  }

  private static boolean getBit(int value, int bit) {
    return ((value >> bit) & 1) != 0;
  }

  private static int partition(int[] arr, int lo, int hi, int bit) {
    int i = lo - 1;
    int j = hi;
    while (true) {
      i++;
      while (i < j && !getBit(arr[i], bit)) {
        i++;
      }
      j--;
      while (j > i && getBit(arr[j], bit)) {
        j--;
      }
      if (i < j) {
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
      } else {
        return i;
      }
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n <= 1) {
      return;
    }

    int maxValue = arr[0];
    for (int value : arr) {
      if (value > maxValue) {
        maxValue = value;
      }
    }

    int q = mostSignificantBit(maxValue);
    if (q < 0) {
      return;
    }

    int m = 0;
    int i = 0;
    int b = n;

    while (i < n) {
      int p = (b - i < 1) ? i : partition(arr, i, b, q);

      if (q == 0) {
        m += 2;
        while (!getBit(m, q + 1)) {
          q++;
        }
        i = b;
        while (b < n && (arr[b] >> (q + 1)) == (m >> (q + 1))) {
          b++;
        }
      } else {
        b = p;
        q--;
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
