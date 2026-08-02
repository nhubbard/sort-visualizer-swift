import java.util.Arrays;

public class binomialheapsort {
  public static void sort(int[] arr) {
    int n = arr.length;

    int index = 2;
    while (index <= n) {
      int maxNode = index;
      while (true) {
        int focus = maxNode;
        int depth = 1;
        while ((focus & depth) == 0) {
          if (arr[focus - depth - 1] > arr[maxNode - 1]) {
            maxNode = focus - depth;
          }
          depth *= 2;
        }
        if (focus != maxNode) {
          int swapTemp = arr[focus - 1];
          arr[focus - 1] = arr[maxNode - 1];
          arr[maxNode - 1] = swapTemp;
        }
        if (focus == maxNode) {
          break;
        }
      }
      index += 2;
    }

    index = n;
    while (index > 2) {
      int maxNode = index;
      int focus = index;
      int depth = 1;
      while (focus != 0) {
        if ((focus & depth) != 0) {
          if (arr[focus - 1] > arr[maxNode - 1]) {
            maxNode = focus;
          }
          focus -= depth;
        }
        depth *= 2;
      }

      if (maxNode != index) {
        focus = index;
        while (true) {
          int swapTemp = arr[focus - 1];
          arr[focus - 1] = arr[maxNode - 1];
          arr[maxNode - 1] = swapTemp;
          focus = maxNode;
          int innerDepth = 1;
          while ((focus & innerDepth) == 0) {
            if (arr[focus - innerDepth - 1] > arr[maxNode - 1]) {
              maxNode = focus - innerDepth;
            }
            innerDepth *= 2;
          }
          if (focus == maxNode) {
            break;
          }
        }
      }
      index -= 1;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
