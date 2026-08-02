import java.util.Arrays;

public class binomialsmoothsort {
  public static int height(int node) {
    int count = 0;
    while ((node >> count) % 2 == 1) {
      count += 1;
    }
    return count;
  }

  public static void thrift(int[] arr, int node, boolean parentFlag, boolean rootFlag) {
    boolean isRoot = rootFlag && (node >= (1 << height(node)));
    if (!isRoot && !parentFlag) {
      return;
    }

    int choice = height(node) - (isRoot ? 0 : 1);
    if (parentFlag) {
      for (int child = choice - 1; child >= 0; child--) {
        if (arr[node - (1 << choice)] <= arr[node - (1 << child)]) {
          choice = child;
        }
      }
    }

    if (arr[node - (1 << choice)] <= arr[node]) {
      return;
    }

    int swapTemp = arr[node];
    arr[node] = arr[node - (1 << choice)];
    arr[node - (1 << choice)] = swapTemp;
    int nextNode = node - (1 << choice);
    thrift(arr, nextNode, nextNode % 2 == 1, choice == height(node));
  }

  public static void sort(int[] arr) {
    int n = arr.length;

    int node = 1;
    while (node < n) {
      thrift(arr, node, node % 2 == 1, (node + (1 << height(node))) >= n);
      node += 1;
    }

    node -= (node - 1) % 2;
    while (node > 2) {
      for (int child = height(node) - 1; child >= 0; child--) {
        thrift(arr, node - (1 << child), false, true);
      }
      node -= 2;
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
