import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class aatreesort {
  private static class Node {
    int value;
    int level;
    Node left;
    Node right;

    Node(int value) {
      this.value = value;
      this.level = 0;
    }
  }

  private static int nodeLevel(Node node) {
    return node == null ? -1 : node.level;
  }

  private static Node skew(Node node) {
    if (node.left == null) {
      return node;
    }
    Node l = node.left;
    node.left = l.right;
    l.right = node;
    return l;
  }

  private static Node split(Node node) {
    if (node.right == null) {
      return node;
    }
    Node r = node.right;
    node.right = r.left;
    r.left = node;
    r.level++;
    return r;
  }

  private static Node add(Node node, int value) {
    if (node == null) {
      return new Node(value);
    }
    if (value < node.value) {
      node.left = add(node.left, value);
      if (nodeLevel(node.left) == node.level) {
        if (node.level != nodeLevel(node.right)) {
          return skew(node);
        }
        node.level++;
        return node;
      }
      return node;
    } else {
      node.right = add(node.right, value);
      if (nodeLevel(node.right.right) == node.level) {
        return split(node);
      }
      return node;
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
      root = add(root, arr[i]);
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
