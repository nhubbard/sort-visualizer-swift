import java.util.Arrays;

public class tablesort {
  public static boolean stableComp(int[] arr, int[] table, int a, int b) {
    int ta = table[a];
    int tb = table[b];
    if (arr[ta] > arr[tb]) {
      return true;
    }
    if (arr[ta] == arr[tb]) {
      return table[a] > table[b];
    }
    return false;
  }

  public static void medianOfThree(int[] arr, int[] table, int a, int b) {
    int m = a + (b - 1 - a) / 2;
    if (stableComp(arr, table, a, m)) {
      int tmp = table[a];
      table[a] = table[m];
      table[m] = tmp;
    }
    if (stableComp(arr, table, m, b - 1)) {
      int tmp = table[m];
      table[m] = table[b - 1];
      table[b - 1] = tmp;
      if (stableComp(arr, table, a, m)) {
        return;
      }
    }
    int tmp = table[a];
    table[a] = table[m];
    table[m] = tmp;
  }

  public static int partition(int[] arr, int[] table, int a, int b, int p) {
    int i = a - 1;
    int j = b;
    while (true) {
      do {
        i++;
      } while (i < j && !stableComp(arr, table, i, p));
      do {
        j--;
      } while (j >= i && stableComp(arr, table, j, p));
      if (i < j) {
        int tmp = table[i];
        table[i] = table[j];
        table[j] = tmp;
      } else {
        return j;
      }
    }
  }

  public static void quickSort(int[] arr, int[] table, int a, int b) {
    if (b - a < 3) {
      if (b - a == 2 && stableComp(arr, table, a, a + 1)) {
        int tmp = table[a];
        table[a] = table[a + 1];
        table[a + 1] = tmp;
      }
      return;
    }
    medianOfThree(arr, table, a, b);
    int p = partition(arr, table, a + 1, b, a);
    int tmp = table[a];
    table[a] = table[p];
    table[p] = tmp;
    quickSort(arr, table, a, p);
    quickSort(arr, table, p + 1, b);
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    int[] table = new int[n];
    for (int i = 0; i < n; i++) {
      table[i] = i;
    }
    quickSort(arr, table, 0, n);
    for (int i = 0; i < n; i++) {
      if (table[i] != i) {
        int t = arr[i];
        int j = i;
        int next = table[i];
        do {
          arr[j] = arr[next];
          table[j] = j;
          j = next;
          next = table[next];
        } while (next != i);
        arr[j] = t;
        table[j] = j;
      }
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
