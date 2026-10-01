import java.util.ArrayList;
import java.util.Arrays;

public class timsort {
  static int minRunLength(int value) {
    int n = value;
    int remainder = 0;
    while (n >= 32) {
      remainder |= n & 1;
      n >>= 1;
    }
    return n + remainder;
  }

  static int countRun(int[] values, int start) {
    int end = start + 1;
    if (end == values.length) {
      return 1;
    }
    boolean descending = values[end] < values[start];
    end++;
    if (descending) {
      while (end < values.length && values[end] < values[end - 1]) {
        end++;
      }
      for (int left = start, right = end - 1; left < right; left++, right--) {
        int value = values[left];
        values[left] = values[right];
        values[right] = value;
      }
    } else {
      while (end < values.length && values[end] >= values[end - 1]) {
        end++;
      }
    }
    return end - start;
  }

  static void binaryInsertion(int[] values, int start, int end, int sortedEnd) {
    for (int index = sortedEnd; index < end; index++) {
      int pivot = values[index];
      int low = start;
      int high = index;
      while (low < high) {
        int middle = low + (high - low) / 2;
        if (values[middle] <= pivot) {
          low = middle + 1;
        } else {
          high = middle;
        }
      }
      for (int shift = index; shift > low; shift--) {
        values[shift] = values[shift - 1];
      }
      values[low] = pivot;
    }
  }

  static void merge(int[] values, ArrayList<int[]> runs, int index) {
    int[] first = runs.get(index);
    int[] second = runs.get(index + 1);
    int[] left = Arrays.copyOfRange(values, first[0], second[0]);
    int[] right = Arrays.copyOfRange(values, second[0], second[0] + second[1]);
    int i = 0;
    int j = 0;
    int destination = first[0];
    while (i < left.length && j < right.length) {
      if (left[i] <= right[j]) {
        values[destination++] = left[i++];
      } else {
        values[destination++] = right[j++];
      }
    }
    while (i < left.length) {
      values[destination++] = left[i++];
    }
    while (j < right.length) {
      values[destination++] = right[j++];
    }
    runs.set(index, new int[] {first[0], first[1] + second[1]});
    runs.remove(index + 1);
  }

  public static void sort(int[] values) {
    int n = values.length;
    if (n < 2) {
      return;
    }
    int minimum = minRunLength(n);
    ArrayList<int[]> runs = new ArrayList<>();
    int cursor = 0;
    while (cursor < n) {
      int length = countRun(values, cursor);
      int forced = Math.min(minimum, n - cursor);
      if (length < forced) {
        binaryInsertion(values, cursor, cursor + forced, cursor + length);
        length = forced;
      }
      runs.add(new int[] {cursor, length});
      while (runs.size() > 1) {
        int index = runs.size() - 2;
        if ((index >= 1 && runs.get(index - 1)[1] <= runs.get(index)[1] + runs.get(index + 1)[1])
            || (index >= 2
                && runs.get(index - 2)[1] <= runs.get(index)[1] + runs.get(index - 1)[1])) {
          if (runs.get(index - 1)[1] < runs.get(index + 1)[1]) {
            index--;
          }
        } else if (runs.get(index)[1] > runs.get(index + 1)[1]) {
          break;
        }
        merge(values, runs, index);
      }
      cursor += length;
    }
    while (runs.size() > 1) {
      int index = runs.size() - 2;
      if (index > 0 && runs.get(index - 1)[1] < runs.get(index + 1)[1]) {
        index--;
      }
      merge(values, runs, index);
    }
  }

  public static void main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
