import java.util.Arrays;

public class weavedmergesort {
  private static void merge(int[] arr, int[] tmp, int length, int residue, int modulus) {
    if (residue + modulus >= length) {
      return;
    }
    int low = residue;
    int high = residue + modulus;
    int dmodulus = modulus << 1;

    merge(arr, tmp, length, low, dmodulus);
    merge(arr, tmp, length, high, dmodulus);

    int nxt = residue;
    while (low < length && high < length) {
      if (arr[low] > arr[high] || (arr[low] == arr[high] && low > high)) {
        tmp[nxt] = arr[high];
        high += dmodulus;
      } else {
        tmp[nxt] = arr[low];
        low += dmodulus;
      }
      nxt += modulus;
    }
    if (low >= length) {
      while (high < length) {
        tmp[nxt] = arr[high];
        nxt += modulus;
        high += dmodulus;
      }
    } else {
      while (low < length) {
        tmp[nxt] = arr[low];
        nxt += modulus;
        low += dmodulus;
      }
    }
    for (int i = residue; i < length; i += modulus) {
      arr[i] = tmp[i];
    }
  }

  public static void sort(int[] arr) {
    int[] tmp = new int[arr.length];
    merge(arr, tmp, arr.length, 0, 1);
  }

  public static void main(String[] args) {
    int[] array = new int[]{0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
