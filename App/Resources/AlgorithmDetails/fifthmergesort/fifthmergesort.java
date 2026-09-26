import java.util.Arrays;

public class fifthmergesort {
  private static void sortRange(int[] arr, int start, int end) {
    int length = end - start;
    if (length < 2) {
      return;
    }
    int[] bounds = new int[6];
    for (int part = 0; part <= 5; part++) {
      bounds[part] = start + length * part / 5;
    }
    for (int part = 0; part < 5; part++) {
      sortRange(arr, bounds[part], bounds[part + 1]);
    }
    int[] positions = Arrays.copyOf(bounds, 5);
    int[] merged = new int[length];
    for (int offset = 0; offset < length; offset++) {
      int best = -1;
      for (int part = 0; part < 5; part++) {
        if (positions[part] < bounds[part + 1]
            && (best < 0 || arr[positions[part]] < arr[positions[best]])) {
          best = part;
        }
      }
      merged[offset] = arr[positions[best]++];
    }
    System.arraycopy(merged, 0, arr, start, length);
  }

  public static void sort(int[] arr) {
    sortRange(arr, 0, arr.length);
  }

  public static void main(String[] args) {
    int[] array = {
      0, 39, 21, 62, 91, 77, 14, 23,
      90, 69, 51, 81, 68, 83, 32, 56
    };
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
