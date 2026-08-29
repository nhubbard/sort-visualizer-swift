import java.util.Arrays;

public class optimizedweavemergesort {
  private static void insertTo(int[] array, int a, int b) {
    int temp = array[a];
    while (a > b) {
      a--;
      array[a + 1] = array[a];
    }
    array[b] = temp;
  }

  private static void multiSwap(int[] array, int a, int b, int len) {
    for (int i = 0; i < len; i++) {
      int temp = array[a + i];
      array[a + i] = array[b + i];
      array[b + i] = temp;
    }
  }

  private static void rotate(int[] array, int a, int m, int b) {
    int l = m - a;
    int r = b - m;
    while (l > 0 && r > 0) {
      if (r < l) {
        multiSwap(array, m - r, m, r);
        b -= r;
        m -= r;
        l -= r;
      } else {
        multiSwap(array, a, m, l);
        a += l;
        m += l;
        r -= l;
      }
    }
  }

  private static void bitReversal(int[] array, int a, int b) {
    int len = b - a;
    int m = 0;
    int d1 = len >> 1;
    int d2 = d1 + (d1 >> 1);
    int i = 1;
    while (i < len - 1) {
      int j = d1;
      int k = i;
      int nn = d2;
      while ((k & 1) == 0) {
        j -= nn;
        k >>= 1;
        nn >>= 1;
      }
      m += j;
      if (m > i) {
        int temp = array[a + i];
        array[a + i] = array[a + m];
        array[a + m] = temp;
      }
      i++;
    }
  }

  private static void weaveInsert(int[] array, int a, int b, boolean rightInit) {
    boolean right = rightInit;
    int i = a;
    int j = a + 1;
    while (j < b) {
      if (right) {
        while (i < j && array[i] <= array[j]) {
          i++;
        }
      } else {
        while (i < j && array[i] < array[j]) {
          i++;
        }
      }
      if (i == j) {
        right = !right;
        j++;
      } else {
        insertTo(array, j, i);
        i++;
        j += 2;
      }
    }
  }

  private static void weaveMerge(int[] array, int a, int mInit, int b) {
    if (b - a < 2) {
      return;
    }
    int a1 = a;
    int b1 = b;
    boolean right = true;
    if ((b - a) % 2 == 1) {
      if (mInit - a < b - mInit) {
        a1 -= 1;
        right = false;
      } else {
        b1 += 1;
      }
    }
    int e = b1;
    while (e - a1 > 2) {
      int m = (a1 + e) / 2;
      int p = 1;
      while (p * 2 <= m - a1) {
        p *= 2;
      }
      rotate(array, m - p, m, e - p);
      m = e - p;
      int f = m - p;
      bitReversal(array, f, m);
      bitReversal(array, m, e);
      bitReversal(array, f, e);
      e = f;
    }
    weaveInsert(array, a, b, right);
  }

  public static void sort(int[] array) {
    int n = array.length;
    if (n <= 1) {
      return;
    }
    int d = 1;
    while (d < n) {
      d <<= 1;
    }
    while (d > 1) {
      int i = 0;
      int dec = 0;
      while (i < n) {
        int j = i;
        dec += n;
        while (dec >= d) {
          dec -= d;
          j++;
        }
        int k = j;
        dec += n;
        while (dec >= d) {
          dec -= d;
          k++;
        }
        weaveMerge(array, i, j, k);
        i = k;
      }
      d /= 2;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
