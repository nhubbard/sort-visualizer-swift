import java.util.Arrays;

public class lazyheapsort {
  public static void maxToFront(int[] arr, int a, int b) {
    int best = a;
    int i = a + 1;
    while (i < b) {
      if (arr[i] > arr[best]) {
        best = i;
      }
      i++;
    }
    int temp = arr[best];
    arr[best] = arr[a];
    arr[a] = temp;
  }

  public static void sort(int arr[]) {
    int n = arr.length;
    int s = (int) Math.sqrt(n - 1) + 1;

    int i = 0;
    while (i < n) {
      maxToFront(arr, i, Math.min(i + s, n));
      i += s;
    }

    int j = n;
    while (j > 0) {
      int best = 0;
      int k = best + s;
      while (k < j) {
        if (arr[k] >= arr[best]) {
          best = k;
        }
        k += s;
      }
      j--;
      int temp = arr[best];
      arr[best] = arr[j];
      arr[j] = temp;
      maxToFront(arr, best, Math.min(best + s, j));
    }
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
