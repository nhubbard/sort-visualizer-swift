import java.util.Arrays;

public class deterministicbogosort {
  public static boolean isSorted(int[] arr) {
    for (int i = 0; i < arr.length - 1; i++) {
      if (arr[i] > arr[i + 1]) {
        return false;
      }
    }
    return true;
  }

  public static boolean permutationSort(int[] arr, int depth, int n) {
    if (depth >= n - 1) {
      return isSorted(arr);
    }
    for (int i = n - 1; i > depth; i--) {
      if (permutationSort(arr, depth + 1, n)) {
        return true;
      }
      if ((n - depth) % 2 == 0) {
        int temp = arr[depth];
        arr[depth] = arr[i];
        arr[i] = temp;
      } else {
        int temp = arr[depth];
        arr[depth] = arr[n - 1];
        arr[n - 1] = temp;
      }
    }
    return permutationSort(arr, depth + 1, n);
  }

  public static void sort(int arr[]) {
    int n = arr.length;
    permutationSort(arr, 0, n);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 14, 23};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
