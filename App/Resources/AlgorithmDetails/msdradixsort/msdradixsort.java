import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class msdradixsort {
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

  private static void radixMSD(int[] array, int low, int high, int radix, int power) {
    if (low >= high || power < 0) {
      return;
    }

    List<List<Integer>> buckets = new ArrayList<>();
    for (int i = 0; i < radix; i++) {
      buckets.add(new ArrayList<>());
    }

    for (int i = low; i < high; i++) {
      buckets.get(getDigit(array[i], power, radix)).add(array[i]);
    }

    int index = low;
    for (List<Integer> bucket : buckets) {
      for (int value : bucket) {
        array[index++] = value;
      }
    }

    int start = low;
    for (List<Integer> bucket : buckets) {
      radixMSD(array, start, start + bucket.size(), radix, power - 1);
      start += bucket.size();
    }
  }

  public static void sort(int[] arr) {
    if (arr.length <= 1) {
      return;
    }
    int radix = 4;
    int maxValue = arr[0];
    for (int value : arr) {
      if (value > maxValue) {
        maxValue = value;
      }
    }
    int highestPower = 0;
    int probe = radix;
    while (probe <= maxValue) {
      highestPower++;
      probe *= radix;
    }
    radixMSD(arr, 0, arr.length, radix, highestPower);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
