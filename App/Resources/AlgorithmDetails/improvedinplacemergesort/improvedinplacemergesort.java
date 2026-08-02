import java.util.Arrays;

public class improvedinplacemergesort {
  private static void push(int[] arr, int p, int a, int b) {
    if (a == b) {
      return;
    }
    int temp = arr[p];
    arr[p] = arr[a];
    for (int i = a + 1; i < b; i++) {
      arr[i - 1] = arr[i];
    }
    arr[b - 1] = temp;
  }

  private static void merge(int[] arr, int a, int m, int b) {
    int i = a;
    int j = m;
    while (i < m && j < b) {
      if (arr[i] > arr[j]) {
        j++;
      } else {
        push(arr, i, m, j);
        i++;
      }
    }
    while (i < m) {
      push(arr, i, m, b);
      i++;
    }
  }

  private static void mergeSort(int[] arr, int a, int b) {
    int m = a + (b - a) / 2;
    if (b - a > 2) {
      if (b - a > 3) {
        mergeSort(arr, a, m);
      }
      mergeSort(arr, m, b);
    }
    merge(arr, a, m, b);
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    mergeSort(arr, 0, n);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
