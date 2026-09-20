import java.util.Arrays;

public class lazystablesort {
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
      if (rest > part) {
        mergeWithoutBuffer(arr, left, part, rest - part);
      }
      part *= 2;
    }
  }

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
    int left = 0;
    int right = len;
    while (left < right) {
      int mid = left + (right - left) / 2;
      boolean cond = isLeft ? arr[pos + mid] < arr[keyPos] : arr[pos + mid] <= arr[keyPos];
      if (cond) {
        left = mid + 1;
      } else {
        right = mid;
      }
    }
    return left;
  }

  public static void mergeWithoutBuffer(int[] arr, int pos, int len1, int len2) {
    if (len1 < len2) {
      while (len1 != 0) {
        int loc = binSearch(arr, pos + len1, len2, pos, true);
        if (loc != 0) {
          rotate(arr, pos, len1, loc);
          pos += loc;
          len2 -= loc;
        }
        if (len2 == 0) break;
        do {
          pos++;
          len1--;
        } while (len1 != 0 && arr[pos] <= arr[pos + len1]);
      }
    } else {
      while (len2 != 0) {
        int loc = binSearch(arr, pos, len1, pos + len1 + len2 - 1, false);
        if (loc != len1) {
          rotate(arr, pos + loc, len1 - loc, len2);
          len1 = loc;
        }
        if (len1 == 0) break;
        do {
          len2--;
        } while (len2 != 0 && arr[pos + len1 - 1] <= arr[pos + len1 + len2 - 1]);
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
