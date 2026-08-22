#include <cstdio>
#include <vector>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

struct Node {
  int value;
  int level;
  Node *left;
  Node *right;

  explicit Node(int value)
      : value(value), level(0), left(nullptr), right(nullptr) {}
};

void printList(int items[], int size) {
  for (int i = 0; i < size; i++) {
    if (i == 0) {
      printf("[%d, ", items[i]);
    } else if (i != size - 1) {
      printf("%d, ", items[i]);
    } else {
      printf("%d]", items[i]);
    }
  }
}

int nodeLevel(Node *node) { return node == nullptr ? -1 : node->level; }

Node *skew(Node *node) {
  if (node->left == nullptr) {
    return node;
  }
  Node *l = node->left;
  node->left = l->right;
  l->right = node;
  return l;
}

Node *split(Node *node) {
  if (node->right == nullptr) {
    return node;
  }
  Node *r = node->right;
  node->right = r->left;
  r->left = node;
  r->level++;
  return r;
}

Node *add(Node *node, int value) {
  if (node == nullptr) {
    return new Node(value);
  }
  if (value < node->value) {
    node->left = add(node->left, value);
    if (nodeLevel(node->left) == node->level) {
      if (node->level != nodeLevel(node->right)) {
        return skew(node);
      }
      node->level++;
      return node;
    }
    return node;
  } else {
    node->right = add(node->right, value);
    if (nodeLevel(node->right->right) == node->level) {
      return split(node);
    }
    return node;
  }
}

void traverse(Node *node, std::vector<int> &result) {
  if (node == nullptr) {
    return;
  }
  traverse(node->left, result);
  result.push_back(node->value);
  traverse(node->right, result);
}

void freeTree(Node *node) {
  if (node == nullptr) {
    return;
  }
  freeTree(node->left);
  freeTree(node->right);
  delete node;
}

void sort(int arr[], int n) {
  Node *root = nullptr;
  for (int i = 0; i < n; i++) {
    root = add(root, arr[i]);
  }

  std::vector<int> result;
  traverse(root, result);

  for (int i = 0; i < n; i++) {
    arr[i] = result[i];
  }

  freeTree(root);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
