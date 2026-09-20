import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class simpleshattersort {
  public static void sort(int[] arr) {
    if (arr.length < 2) return;
    int n = arr.length;
    int rate = Math.max(2, floorLog2(n) / 2);
    simpleShatterSort(arr, n, 4, rate);
  }

  public static void insertionSort(int[] arr, int start, int end) {
    for (int i = start + 1; i < end; i++) {
      int pos = i;
      while (pos > start && arr[pos - 1] > arr[pos]) {
        int temp = arr[pos - 1];
        arr[pos - 1] = arr[pos];
        arr[pos] = temp;
        pos--;
      }
    }
  }

  public static int[] shatterPartition(int[] arr, int start, int length, int num) {
    int minV = arr[start];
    int maxV = arr[start];
    for (int i = 1; i < length; i++) {
      if (arr[start + i] < minV) {
        minV = arr[start + i];
      }
      if (arr[start + i] > maxV) {
        maxV = arr[start + i];
      }
    }
    int valueRange = maxV - minV + 1;
    int shatters = (length + num - 1) / num;

    List<List<Integer>> buckets = new ArrayList<>();
    for (int i = 0; i < shatters; i++) {
      buckets.add(new ArrayList<>());
    }

    for (int i = 0; i < length; i++) {
      int v = arr[start + i];
      int idx = (v - minV) * shatters / valueRange;
      if (idx > shatters - 1) {
        idx = shatters - 1;
      }
      buckets.get(idx).add(v);
    }

    int[] offsets = new int[shatters + 1];
    for (int i = 0; i < shatters; i++) {
      offsets[i + 1] = offsets[i] + buckets.get(i).size();
    }

    int pos = start;
    for (List<Integer> bucket : buckets) {
      for (int v : bucket) {
        arr[pos++] = v;
      }
    }
    return offsets;
  }

  public static int floorLog2(int n) {
    int log = 0;
    int m = n;
    while (m > 1) {
      m >>= 1;
      log++;
    }
    return log;
  }

  public static void simpleShatterSort(int[] arr, int length, int num, int rate) {
    int i = num;
    while (i > 1) {
      shatterPartition(arr, 0, length, i);
      i = i / rate;
    }
    int[] offsets = shatterPartition(arr, 0, length, 1);
    for (int k = 0; k < offsets.length - 1; k++) {
      if (offsets[k + 1] - offsets[k] > 1) {
        insertionSort(arr, offsets[k], offsets[k + 1]);
      }
    }
  }

  public static void main(String[] args) {
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56
    };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
