import java.util.Arrays;

public class splaysort {
  private static int idx;

  private static class Node {
    int key;
    Node left;
    Node right;

    Node(int key) {
      this.key = key;
    }
  }

  private static Node leftRotate(Node x) {
    Node y = x.right;
    x.right = y.left;
    y.left = x;
    return y;
  }

  private static Node rightRotate(Node x) {
    Node y = x.left;
    x.left = y.right;
    y.right = x;
    return y;
  }

  private static Node splay(Node root, int key) {
    if (root == null) {
      return root;
    }
    if (root.key > key) {
      if (root.left == null) {
        return root;
      }
      if (root.left.key > key) {
        root.left.left = splay(root.left.left, key);
        root = rightRotate(root);
      } else {
        root.left.right = splay(root.left.right, key);
        if (root.left.right != null) {
          root.left = leftRotate(root.left);
        }
      }
      return root.left == null ? root : rightRotate(root);
    } else {
      if (root.right == null) {
        return root;
      }
      if (root.right.key > key) {
        root.right.left = splay(root.right.left, key);
        if (root.right.left != null) {
          root.right = rightRotate(root.right);
        }
      } else {
        root.right.right = splay(root.right.right, key);
        root = leftRotate(root);
      }
      return root.right == null ? root : leftRotate(root);
    }
  }

  private static Node insertRec(Node root, int key) {
    if (root == null) {
      return new Node(key);
    }
    root = splay(root, key);
    Node n = new Node(key);
    if (root.key > key) {
      n.right = root;
      n.left = root.left;
      root.left = null;
    } else {
      n.left = root;
      n.right = root.right;
      root.right = null;
    }
    return n;
  }

  private static void traverse(Node node, int[] result) {
    if (node != null) {
      traverse(node.left, result);
      result[idx++] = node.key;
      traverse(node.right, result);
    }
  }

  public static void sort(int[] arr) {
    int n = arr.length;
    Node root = null;
    for (int x : arr) {
      root = insertRec(root, x);
    }
    int[] result = new int[n];
    idx = 0;
    traverse(root, result);
    System.arraycopy(result, 0, arr, 0, n);
  }

  public static void main(String[] args) {
    int[] array = new int[] {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
