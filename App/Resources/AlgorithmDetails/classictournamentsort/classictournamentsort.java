import java.util.Arrays;

public final class classictournamentsort {
  static int ceilPow2(int value) {
    int r = 1;
    while (r < value) {
      r *= 2;
    }
    return r;
  }

  static boolean treeCompare(int[] array, int[] tree, int a, int b) {
    return array[tree[a]] <= array[tree[b]];
  }

  static int findNext(int[] array, int[] tree, int size) {
    int path = tree[0] + size;
    while (path > 0) {
      tree[path] = -1;
      path = (path - 1) / 2;
    }

    int node = tree[0] + size;
    while (node > 0) {
      int sibling = node % 2 == 1 ? node + 1 : node - 1;
      boolean nodeValid = tree[node] != -1;
      boolean siblingValid = tree[sibling] != -1;
      int winner;
      if (nodeValid && siblingValid) {
        winner =
            node < sibling
                ? (treeCompare(array, tree, node, sibling) ? tree[node] : tree[sibling])
                : (treeCompare(array, tree, sibling, node) ? tree[sibling] : tree[node]);
      } else if (nodeValid) {
        winner = tree[node];
      } else if (siblingValid) {
        winner = tree[sibling];
      } else {
        winner = -1;
      }
      node = (node - 1) / 2;
      if (winner != -1) {
        tree[node] = winner;
      }
    }
    return array[tree[0]];
  }

  static void sort(int[] array) {
    int n = array.length;
    if (n <= 1) {
      return;
    }

    int size = ceilPow2(n) - 1;
    int mod = n % 2;
    int treeSize = n + size + mod;
    int[] tree = new int[treeSize];
    Arrays.fill(tree, -1);

    for (int i = size; i < treeSize - mod; i++) {
      tree[i] = i - size;
    }

    int j = size;
    int k = treeSize - mod;
    while (j > 0) {
      int i = j;
      while (i + 1 < k) {
        tree[i / 2] = treeCompare(array, tree, i, i + 1) ? tree[i] : tree[i + 1];
        i += 2;
      }
      if (i < k) {
        tree[i / 2] = tree[i];
      }
      j /= 2;
      k /= 2;
    }

    int[] output = new int[n];
    output[0] = array[tree[0]];
    for (int i = 1; i < n; i++) {
      output[i] = findNext(array, tree, size);
    }
    System.arraycopy(output, 0, array, 0, n);
  }

  public static void main(String[] args) {
    int[] array = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(array);
    System.out.println(Arrays.toString(array));
  }
}
