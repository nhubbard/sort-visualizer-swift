import java.util.Arrays;

/* TODO: Rename class to match file name (Java specific). */
public class quicksort {
  /* TODO: Insert Java algorithm implementation here. */

  public static void main(String[] args) {
    int[] items = new int[]{35, 95, 74, 71, 72, 30, 96, 53, 9, 0};
    quickSort(items, 0, items.length - 1);
    System.out.println(Arrays.toString(items));
  }
}
