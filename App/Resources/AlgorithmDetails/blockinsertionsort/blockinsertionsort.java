import java.util.Arrays;

public class blockinsertionsort {
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

  public static int findRun(int[] arr, int a, int b) {
    int i = a + 1;
    if (i == b) return i;
    if (arr[i - 1] > arr[i]) {
      i++;
      while (i < b && arr[i - 1] > arr[i]) i++;
      int lo = a, hi = i - 1;
      while (lo < hi) {
        int t = arr[lo];
        arr[lo] = arr[hi];
        arr[hi] = t;
        lo++;
        hi--;
      }
    } else {
      i++;
      while (i < b && arr[i - 1] <= arr[i]) i++;
    }
    return i;
  }

  public static void insert1(int[] arr, int a, int l) {
    int tmp = arr[l];
    l--;
    while (l >= a && arr[l] > tmp) {
      arr[l + 1] = arr[l];
      l--;
    }
    arr[l + 1] = tmp;
  }

  public static void insert2(int[] arr, int a, int l, int r) {
    int tmpL = arr[l];
    int tmpR = arr[r];
    l--;
    while (l >= a && arr[l] > tmpR) {
      arr[l + 2] = arr[l];
      l--;
    }
    arr[l + 2] = tmpR;
    while (l >= a && arr[l] > tmpL) {
      arr[l + 1] = arr[l];
      l--;
    }
    arr[l + 1] = tmpL;
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    int i = findRun(arr, 0, n);
    while (i < n) {
      int j = findRun(arr, i, n);
      int len = j - i;
      if (len == 1) insert1(arr, 0, i);
      else if (len == 2) insert2(arr, 0, i, i + 1);
      else mergeWithoutBuffer(arr, 0, i, len);
      i = j;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
