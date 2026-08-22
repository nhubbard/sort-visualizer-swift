import java.util.Arrays;

public class bosenelsonsortrecursive {
  private static void compSwap(int[] arr, int start, int end) {
    if (arr[start] > arr[end]) {
      int temp = arr[start];
      arr[start] = arr[end];
      arr[end] = temp;
    }
  }

  private static void merge(int[] arr, int start1, int len1, int start2, int len2) {
    if (len1 == 1 && len2 == 1) {
      compSwap(arr, start1, start2);
    } else if (len1 == 1 && len2 == 2) {
      compSwap(arr, start1, start2 + 1);
      compSwap(arr, start1, start2);
    } else if (len1 == 2 && len2 == 1) {
      compSwap(arr, start1, start2);
      compSwap(arr, start1 + 1, start2);
    } else {
      int mid1 = len1 / 2;
      int mid2 = (len1 % 2 == 1) ? len2 / 2 : (len2 + 1) / 2;
      merge(arr, start1, mid1, start2, mid2);
      merge(arr, start1 + mid1, len1 - mid1, start2 + mid2, len2 - mid2);
      merge(arr, start1 + mid1, len1 - mid1, start2, mid2);
    }
  }

  private static void boseNelson(int[] arr, int start, int length) {
    if (length > 1) {
      int mid = length / 2;
      boseNelson(arr, start, mid);
      boseNelson(arr, start + mid, length - mid);
      merge(arr, start, mid, start + mid, length - mid);
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    boseNelson(arr, 0, n);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
