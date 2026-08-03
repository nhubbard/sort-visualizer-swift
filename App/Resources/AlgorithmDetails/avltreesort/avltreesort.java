import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class avltreesort {
  private static class Node {
    int value;
    Node left;
    Node right;
    int balance;

    Node(int value) {
      this.value = value;
    }
  }

  private static class AddResult {
    Node node;
    boolean heightChanged;

    AddResult(Node node, boolean heightChanged) {
      this.node = node;
      this.heightChanged = heightChanged;
    }
  }

  private static Node singleRotateRight(Node node) {
    Node b = node.left;
    node.left = b.right;
    b.right = node;
    node.balance = 0;
    b.balance = 0;
    return b;
  }

  private static Node singleRotateLeft(Node node) {
    Node b = node.right;
    node.right = b.left;
    b.left = node;
    node.balance = 0;
    b.balance = 0;
    return b;
  }

  private static Node doubleRotateRight(Node node) {
    int oldBBalance = node.left.right.balance;
    node.left = singleRotateLeft(node.left);
    Node b = singleRotateRight(node);
    if (oldBBalance == -1) {
      b.right.balance = 1;
    }
    if (oldBBalance == 1) {
      b.left.balance = -1;
    }
    return b;
  }

  private static Node doubleRotateLeft(Node node) {
    int oldBBalance = node.right.left.balance;
    node.right = singleRotateRight(node.right);
    Node b = singleRotateLeft(node);
    if (oldBBalance == -1) {
      b.right.balance = 1;
    }
    if (oldBBalance == 1) {
      b.left.balance = -1;
    }
    return b;
  }

  private static AddResult heightChangeLeft(Node node) {
    if (node.balance != -1) {
      node.balance -= 1;
      return new AddResult(node, node.balance == -1);
    }
    if (node.left.balance == -1) {
      return new AddResult(singleRotateRight(node), false);
    }
    return new AddResult(doubleRotateRight(node), false);
  }

  private static AddResult heightChangeRight(Node node) {
    if (node.balance != 1) {
      node.balance += 1;
      return new AddResult(node, node.balance == 1);
    }
    if (node.right.balance == 1) {
      return new AddResult(singleRotateLeft(node), false);
    }
    return new AddResult(doubleRotateLeft(node), false);
  }

  private static AddResult add(Node node, int value) {
    if (node == null) {
      return new AddResult(new Node(value), true);
    }
    if (value < node.value) {
      AddResult result = add(node.left, value);
      node.left = result.node;
      if (result.heightChanged) {
        return heightChangeLeft(node);
      }
      return new AddResult(node, false);
    } else {
      AddResult result = add(node.right, value);
      node.right = result.node;
      if (result.heightChanged) {
        return heightChangeRight(node);
      }
      return new AddResult(node, false);
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
    Node root = null;
    for (int value : arr) {
      root = add(root, value).node;
    }

    List<Integer> result = new ArrayList<>();
    traverse(root, result);

    for (int i = 0; i < arr.length; i++) {
      arr[i] = result.get(i);
    }
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
