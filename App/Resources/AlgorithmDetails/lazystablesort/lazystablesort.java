import java.util.Arrays;

public class lazystablesort {
  public static void multiSwap(int[] arr, int a, int b, int count) {
    for (int i = 0; i < count; i++) {
      int t = arr[a + i];
      arr[a + i] = arr[b + i];
      arr[b + i] = t;
    }
  }

  public static void rotate(int[] arr, int pos, int lenA, int lenB) {
    while (lenA != 0 && lenB != 0) {
      if (lenA <= lenB) {
        multiSwap(arr, pos, pos + lenA, lenA);
        pos += lenA;
        lenB -= lenA;
      } else {
        multiSwap(arr, pos + (lenA - lenB), pos + lenA, lenB);
        lenA -= lenB;
      }
    }
  }

  public static int binSearch(int[] arr, int pos, int len, int keyPos, boolean isLeft) {
    int left = 0, right = len;
    while (left < right) {
      int mid = left + (right - left) / 2;
      boolean cond = isLeft ? arr[pos + mid] < arr[keyPos] : arr[pos + mid] <= arr[keyPos];
      if (cond) left = mid + 1;
      else right = mid;
    }
    return left;
  }

  public static void mergeWithoutBuffer(int[] arr, int pos, int len1, int len2) {
    if (len1 == 0 || len2 == 0) return;
    if (len1 == 1) {
      int loc = binSearch(arr, pos + 1, len2, pos, true);
      rotate(arr, pos, 1, loc);
      return;
    }
    if (len2 == 1) {
      int loc = binSearch(arr, pos, len1, pos + len1, false);
      rotate(arr, pos + loc, len1 - loc, 1);
      return;
    }
    int mid1 = len1 / 2;
    int loc = binSearch(arr, pos + len1, len2, pos + mid1, true);
    rotate(arr, pos + mid1, len1 - mid1, loc);
    mergeWithoutBuffer(arr, pos, mid1, loc);
    mergeWithoutBuffer(arr, pos + mid1 + loc, len1 - mid1, len2 - loc);
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    int dist = 1;
    while (dist < n) {
      if (arr[dist - 1] > arr[dist]) {
        int t = arr[dist - 1];
        arr[dist - 1] = arr[dist];
        arr[dist] = t;
      }
      dist += 2;
    }
    int part = 2;
    while (part < n) {
      int left = 0;
      int right = n - 2 * part;
      while (left <= right) {
        mergeWithoutBuffer(arr, left, part, part);
        left += 2 * part;
      }
      int rest = n - left;
      if (rest > part) mergeWithoutBuffer(arr, left, part, rest - part);
      part *= 2;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
