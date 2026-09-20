import java.util.Arrays;

public class mergeinsertionsort {
  static void blockSwap(int[] arr, int a, int b, int size) {
    for (int offset = 0; offset < size; offset++) {
      int x = a - size + 1 + offset, y = b - size + 1 + offset;
      int tmp = arr[x]; arr[x] = arr[y]; arr[y] = tmp;
    }
  }
  static void blockInsert(int[] arr, int a, int b, int size) {
    while (a - size >= b) { blockSwap(arr, a - size, a, size); a -= size; }
  }
  static void blockReversal(int[] arr, int a, int b, int size) {
    b -= size;
    while (b > a) { blockSwap(arr, a, b, size); a += size; b -= size; }
  }
  static int blockSearch(int[] arr, int a, int b, int size, int value) {
    while (a < b) {
      int mid = a + (((b - a) / size) / 2) * size;
      if (value < arr[mid]) b = mid;
      else a = mid + size;
    }
    return a;
  }
  static void order(int[] arr, int a, int b, int size) {
    int i = a, j = i + size;
    while (j < b) { blockInsert(arr, j, i, size); i += size; j += 2 * size; }
    int mid = a + (((b - a) / size) / 2) * size;
    blockReversal(arr, mid, b, size);
  }
  public static void sort(int[] arr) {
    int length = arr.length;
    if (length < 2) return;
    int k = 1;
    while (2 * k <= length) {
      for (int i = 2 * k - 1; i < length; i += 2 * k)
        if (arr[i - k] > arr[i]) blockSwap(arr, i - k, i, k);
      k *= 2;
    }
    while (k > 0) {
      int a = k - 1, i = a + 2 * k, g = 2, p = 4;
      while (i + 2 * k * g - k <= length) {
        order(arr, i, i + 2 * k * g - k, k);
        int b = a + k * (p - 1);
        i += k * g - k;
        for (int j = i; j < i + k * g; j += k)
          blockInsert(arr, j, blockSearch(arr, a, b, k, arr[j]), k);
        i += k * g + k;
        g = p - g; p *= 2;
      }
      while (i < length) {
        blockInsert(arr, i, blockSearch(arr, a, i, k, arr[i]), k);
        i += 2 * k;
      }
      k /= 2;
    }
  }

  public static void main(String[] args) {
    int[] array = {
      34, 7, 23, 90, 12, 56, 3, 45, 78, 21, 66, 9, 50, 15, 88, 40, 61, 5, 33, 72, 18, 95, 27, 60
    };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
