#include <iostream>
#include <vector>

int ceilPow2(int value) {
  int r = 1;
  while (r < value) {
    r *= 2;
  }
  return r;
}

void sort(std::vector<int> &array) {
  int n = static_cast<int>(array.size());
  if (n <= 1)
    return;

  int size = ceilPow2(n) - 1;
  int mod = n % 2;
  int treeSize = n + size + mod;
  std::vector<int> tree(treeSize, -1);

  auto treeCompare = [&](int a, int b) {
    return array[tree[a]] <= array[tree[b]];
  };

  for (int i = size; i < treeSize - mod; i++) {
    tree[i] = i - size;
  }

  int j = size;
  int k = treeSize - mod;
  while (j > 0) {
    int i = j;
    while (i + 1 < k) {
      tree[i / 2] = treeCompare(i, i + 1) ? tree[i] : tree[i + 1];
      i += 2;
    }
    if (i < k) {
      tree[i / 2] = tree[i];
    }
    j /= 2;
    k /= 2;
  }

  auto findNext = [&]() -> int {
    int path = tree[0] + size;
    while (path > 0) {
      tree[path] = -1;
      path = (path - 1) / 2;
    }

    int node = tree[0] + size;
    while (node > 0) {
      int sibling = (node % 2 == 1) ? node + 1 : node - 1;
      bool nodeValid = tree[node] != -1;
      bool siblingValid = tree[sibling] != -1;
      int winner;
      if (nodeValid && siblingValid) {
        winner =
            (node < sibling)
                ? (treeCompare(node, sibling) ? tree[node] : tree[sibling])
                : (treeCompare(sibling, node) ? tree[sibling] : tree[node]);
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
  };

  std::vector<int> output(n);
  output[0] = array[tree[0]];
  for (int i = 1; i < n; i++) {
    output[i] = findNext();
  }
  array = output;
}

int main() {
  std::vector<int> array = {0,  39, 21, 62, 91, 77, 14, 23,
                            90, 69, 51, 81, 68, 83, 32, 56};
  sort(array);
  std::cout << "[";
  for (size_t i = 0; i < array.size(); i++) {
    std::cout << array[i];
    if (i != array.size() - 1)
      std::cout << ", ";
  }
  std::cout << "]" << '\n';
  return 0;
}
