import java.util.Arrays;

public class inplacelsdradixsort {
  private static int intPow(int base, int exponent) {
    int result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  private static int getDigit(int value, int power, int radix) {
    return (value / intPow(radix, power)) % radix;
  }

  private static void multiSwap(int[] arr, int pos, int to) {
    if (to > pos) {
      for (int k = pos; k < to; k++) {
        int temp = arr[k];
        arr[k] = arr[k + 1];
        arr[k + 1] = temp;
      }
    } else if (to < pos) {
      for (int k = pos; k > to; k--) {
        int temp = arr[k];
        arr[k] = arr[k - 1];
        arr[k - 1] = temp;
      }
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n == 0) {
      return;
    }
    int radix = 4;
    int maxValue = arr[0];
    for (int value : arr) {
      if (value > maxValue) {
        maxValue = value;
      }
    }

    int maxPower = 0;
    int probe = radix;
    while (probe <= maxValue) {
      maxPower++;
      probe *= radix;
    }

    int[] vregs = new int[radix - 1];

    for (int power = 0; power <= maxPower; power++) {
      for (int i = 0; i < vregs.length; i++) {
        vregs[i] = n - 1;
      }

      int pos = 0;
      for (int step = 0; step < n; step++) {
        int digit = getDigit(arr[pos], power, radix);
        if (digit == 0) {
          pos++;
        } else {
          int to = vregs[digit - 1];
          multiSwap(arr, pos, to);
          for (int j = digit - 1; j > 0; j--) {
            vregs[j - 1]--;
          }
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
