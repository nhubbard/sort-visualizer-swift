import java.util.Arrays;

public class stablepermutationsort {
  public static boolean isSorted(int[] arr) {
    for (int i = 1; i < arr.length; i++) {
      if (arr[i] < arr[i - 1]) {
        return false;
      }
    }
    return true;
  }

  public static boolean permute(int[] arr, int[] idx, int length, int n) {
    if (length < 2) {
      return isSorted(arr);
    }
    for (int i = length - 2; i >= 0; i--) {
      if (permute(arr, idx, length - 1, n)) {
        return true;
      }
      int t1 = arr[idx[i]];
      arr[idx[i]] = arr[idx[length - 1]];
      arr[idx[length - 1]] = t1;
      int t2 = idx[i];
      idx[i] = idx[length - 1];
      idx[length - 1] = t2;
    }
    if (permute(arr, idx, length - 1, n)) {
      return true;
    }
    int t = idx[length - 1];
    for (int i = length - 1; i > 0; i--) {
      idx[i] = idx[i - 1];
    }
    idx[0] = t;
    t = arr[idx[0]];
    for (int i = 1; i < length; i++) {
      arr[idx[i - 1]] = arr[idx[i]];
    }
    arr[idx[length - 1]] = t;
    return false;
  }

  public static void sort(int arr[]) {
    int n = arr.length;
    int[] idx = new int[n];
    for (int i = 0; i < n; i++) {
      idx[i] = i;
    }
    permute(arr, idx, n, n);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 14, 23};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
