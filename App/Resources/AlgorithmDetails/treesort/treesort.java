import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class treesort {
  private static class Node {
    int pointer;
    Node left;
    Node right;

    Node(int pointer) {
      this.pointer = pointer;
    }
  }

  private static Node add(int[] arr, Node node, int addPtr) {
    if (node == null) {
      return new Node(addPtr);
    }
    if (arr[addPtr] < arr[node.pointer]) {
      node.left = add(arr, node.left, addPtr);
    } else {
      node.right = add(arr, node.right, addPtr);
    }
    return node;
  }

  private static void traverse(int[] arr, Node node, List<Integer> result) {
    if (node == null) {
      return;
    }
    traverse(arr, node.left, result);
    result.add(arr[node.pointer]);
    traverse(arr, node.right, result);
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    Node root = null;
    for (int i = 0; i < n; i++) {
      root = add(arr, root, i);
    }

    List<Integer> result = new ArrayList<>();
    traverse(arr, root, result);

    for (int i = 0; i < n; i++) {
      arr[i] = result.get(i);
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
