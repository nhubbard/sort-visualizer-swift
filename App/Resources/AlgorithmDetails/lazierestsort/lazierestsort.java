import java.util.Arrays;

public class lazierestsort {
  private static void reverse(int[] arr, int a, int b) {
    b--;
    while (a < b) {
      int t = arr[a];
      arr[a++] = arr[b];
      arr[b--] = t;
    }
  }

  private static void rotate(int[] arr, int a, int m, int b) {
    reverse(arr, a, m);
    reverse(arr, m, b);
    reverse(arr, a, b);
  }

  private static int search(int[] arr, int a, int b, int value, boolean upper) {
    while (a < b) {
      int mid = (a + b) / 2;
      if (value < arr[mid] || (!upper && value == arr[mid])) {
        b = mid;
      } else {
        a = mid + 1;
      }
    }
    return a;
  }

  private static int gallop(int[] arr, int a, int b, int value, boolean backwards) {
    int step = 1;
    if (backwards) {
      while (b - step >= a && value < arr[b - step]) {
        step *= 2;
      }
      return search(arr, Math.max(a, b - step + 1), b - step / 2, value, true);
    }
    while (a - 1 + step < b && value > arr[a - 1 + step]) {
      step *= 2;
    }
    return search(arr, a + step / 2, Math.min(b, a - 1 + step), value, false);
  }

  private static void insertion(int[] arr, int a, int b) {
    for (int i = a + 1; i < b; i++) {
      int value = arr[i];
      int position = search(arr, a, i, value, true);
      for (int j = i; j > position; j--) {
        arr[j] = arr[j - 1];
      }
      arr[position] = value;
    }
  }

  private static void forward(int[] arr, int a, int m, int b) {
    int i = a;
    int j = m;
    while (i < j && j < b) {
      if (arr[i] > arr[j]) {
        int k = gallop(arr, j + 1, b, arr[i], false);
        rotate(arr, i, j, k);
        i += k - j;
        j = k;
      } else {
        i++;
      }
    }
  }

  private static void backward(int[] arr, int a, int m, int b) {
    int i = m - 1;
    int j = b - 1;
    while (j > i && i >= a) {
      if (arr[i] > arr[j]) {
        int k = gallop(arr, a, i, arr[j], true);
        rotate(arr, k, i + 1, j + 1);
        j -= i + 1 - k;
        i = k - 1;
      } else {
        j--;
      }
    }
  }

  private static void merge(int[] arr, int a, int m, int b) {
    if (b - m < m - a) {
      backward(arr, a, m, b);
    } else {
      forward(arr, a, m, b);
    }
  }

  private static void fragmented(int[] arr, int a, int m, int b, int size) {
    int i = a + (m - a) % size;
    while (i < m) {
      int j = gallop(arr, m, b, arr[i], false);
      rotate(arr, i, m, j);
      int length = j - m;
      int boundary = i;
      i += length;
      m += length;
      merge(arr, a, boundary, i);
      a = i;
      i += size;
    }
    merge(arr, Math.max(a, i - size), i, b);
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    if (n <= 16) {
      insertion(arr, 0, n);
      return;
    }
    int size = 1;
    while (size * size * size < n) {
      size++;
    }
    int group = size * size;
    for (int i = n % size; i <= n; i += size) {
      insertion(arr, Math.max(0, i - size), i);
    }
    int i = n - size;
    int j = n;
    while (i > 0) {
      if (j - i == group) {
        j -= group;
        i -= size;
      }
      forward(arr, Math.max(0, i - size), i, j);
      i -= size;
    }
    for (i = n - group; i > 0; i -= group) {
      fragmented(arr, Math.max(0, i - group), i, n, size);
    }
  }

  public static void main(String[] args) {
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56,
      10, 2, 95, 46, 21, 74, 6, 38
    };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
