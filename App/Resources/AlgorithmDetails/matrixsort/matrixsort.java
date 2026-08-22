import java.util.Arrays;

public class matrixsort {
  private static int dirCompareVal(int left, int right, boolean dir) {
    int res;
    if (left > right) {
      res = 1;
    } else if (left < right) {
      res = -1;
    } else {
      res = 0;
    }
    return dir ? res : -res;
  }

  private static void gapReverse(int[] arr, int start, int end, int gap) {
    int i = start;
    int j = end;
    while (i < j) {
      int tmp = arr[i];
      arr[i] = arr[j - gap];
      arr[j - gap] = tmp;
      i += gap;
      j -= gap;
    }
  }

  private static boolean insertLast(int[] arr, int a, int b, int gap, boolean dir) {
    boolean did = false;
    int key = arr[b];
    int j = b - gap;
    while (j >= a && dirCompareVal(key, arr[j], dir) < 0) {
      arr[j + gap] = arr[j];
      did = true;
      j -= gap;
    }
    arr[j + gap] = key;
    return did;
  }

  private static final class MatrixShape {
    final int width;
    final boolean insertLast;

    MatrixShape(int width, boolean insertLast) {
      this.width = width;
      this.insertLast = insertLast;
    }
  }

  private static MatrixShape getMatrixDims(int length) {
    int dim = (int) Math.sqrt(length);
    boolean insertLastFlag = dim * dim == length - 1;
    while (length % dim != 0) {
      dim -= 1;
    }
    int width = dim;
    int height = length / dim;
    boolean unbalanced = (width == 1) != (height == 1);
    return new MatrixShape(width, unbalanced || insertLastFlag);
  }

  private static boolean matrixSort(int[] arr, int start, int end, int gap, boolean dir) {
    int length = (end - start) / gap;
    if (length < 2) {
      return false;
    } else if (length <= 16) {
      boolean did = false;
      int i = start;
      while (i < end) {
        did = insertLast(arr, start, i, gap, dir) || did;
        i += gap;
      }
      return did;
    } else {
      MatrixShape matShape = getMatrixDims(length);
      if (matShape.insertLast) {
        boolean did1 = matrixSort(arr, start, end - gap, gap, dir);
        boolean did2 = insertLast(arr, start, end - gap, gap, dir);
        return did1 || did2;
      }

      int i = start + matShape.width * gap;
      while (i < end) {
        gapReverse(arr, i, i + matShape.width * gap, gap);
        i += 2 * matShape.width * gap;
      }

      boolean did = false;
      boolean newdid = true;
      while (newdid) {
        newdid = false;
        boolean curdir = dir;
        i = start;
        while (i < end) {
          newdid = matrixSort(arr, i, i + matShape.width * gap, gap, curdir) || newdid;
          did = did || newdid;
          curdir = !curdir;
          i += matShape.width * gap;
        }

        newdid = false;
        for (int k = 0; k < matShape.width; k++) {
          newdid =
              matrixSort(arr, start + k * gap, end + k * gap, gap * matShape.width, dir) || newdid;
          did = did || newdid;
        }
      }
      i = start + matShape.width * gap;
      while (i < end) {
        gapReverse(arr, i, i + matShape.width * gap, gap);
        i += 2 * matShape.width * gap;
      }

      return did;
    }
  }

  public static void sort(int[] arr) {
    matrixSort(arr, 0, arr.length, 1, true);
  }

  public static void main(String[] args) {
    int[] array =
        new int[] {
          15, 3, 22, 8, 19, 1, 24, 11, 6, 20, 9, 17, 2, 14, 23, 5, 18, 0, 12, 21, 7, 16, 4, 13, 10
        };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
