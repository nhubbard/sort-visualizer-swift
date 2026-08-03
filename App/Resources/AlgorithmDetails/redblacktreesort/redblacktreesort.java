import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class redblacktreesort {
  private static class Node {
    int value;
    Node left;
    Node right;
    boolean isRed = true;

    Node(int value) {
      this.value = value;
    }
  }

  private static class AddResult {
    Node node;
    boolean needsFix;

    AddResult(Node node, boolean needsFix) {
      this.node = node;
      this.needsFix = needsFix;
    }
  }

  private static boolean isRed(Node node) {
    return node != null && node.isRed;
  }

  private static Node singleRotateRight(Node node) {
    Node b = node.left;
    node.left = b.right;
    b.right = node;
    b.isRed = false;
    node.isRed = true;
    return b;
  }

  private static Node singleRotateLeft(Node node) {
    Node b = node.right;
    node.right = b.left;
    b.left = node;
    b.isRed = false;
    node.isRed = true;
    return b;
  }

  private static Node doubleRotateRight(Node node) {
    node.left = singleRotateLeft(node.left);
    return singleRotateRight(node);
  }

  private static Node doubleRotateLeft(Node node) {
    node.right = singleRotateRight(node.right);
    return singleRotateLeft(node);
  }

  private static AddResult add(Node node, int value) {
    if (node == null) {
      return new AddResult(new Node(value), false);
    }

    if (!node.isRed && isRed(node.left) && isRed(node.right)) {
      node.isRed = true;
      node.left.isRed = false;
      node.right.isRed = false;
    }

    if (value < node.value) {
      AddResult child = add(node.left, value);
      node.left = child.node;
      if (child.needsFix) {
        if (isRed(node.left.left)) {
          return new AddResult(singleRotateRight(node), false);
        }
        return new AddResult(doubleRotateRight(node), false);
      }
      return new AddResult(node, node.isRed && isRed(node.left));
    } else {
      AddResult child = add(node.right, value);
      node.right = child.node;
      if (child.needsFix) {
        if (isRed(node.right.right)) {
          return new AddResult(singleRotateLeft(node), false);
        }
        return new AddResult(doubleRotateLeft(node), false);
      }
      return new AddResult(node, node.isRed && isRed(node.right));
    }
  }

  private static void traverse(Node node, List<Integer> result) {
    if (node == null) {
      return;
    }
    traverse(node.left, result);
    result.add(node.value);
    traverse(node.right, result);
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    Node root = null;
    for (int i = 0; i < n; i++) {
      AddResult inserted = add(root, arr[i]);
      root = inserted.node;
      root.isRed = false;
    }

    List<Integer> result = new ArrayList<>();
    traverse(root, result);

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
