#include <cstdio>
#include <vector>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

struct Node {
  int value;
  Node *left;
  Node *right;
  bool isRed;

  explicit Node(int value)
      : value(value), left(nullptr), right(nullptr), isRed(true) {}
};

struct AddResult {
  Node *node;
  bool needsFix;
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

bool isRed(Node *node) { return node != nullptr && node->isRed; }

Node *singleRotateRight(Node *node) {
  Node *b = node->left;
  node->left = b->right;
  b->right = node;
  b->isRed = false;
  node->isRed = true;
  return b;
}

Node *singleRotateLeft(Node *node) {
  Node *b = node->right;
  node->right = b->left;
  b->left = node;
  b->isRed = false;
  node->isRed = true;
  return b;
}

Node *doubleRotateRight(Node *node) {
  node->left = singleRotateLeft(node->left);
  return singleRotateRight(node);
}

Node *doubleRotateLeft(Node *node) {
  node->right = singleRotateRight(node->right);
  return singleRotateLeft(node);
}

AddResult add(Node *node, int value) {
  if (node == nullptr) {
    return {new Node(value), false};
  }

  if (!node->isRed && isRed(node->left) && isRed(node->right)) {
    node->isRed = true;
    node->left->isRed = false;
    node->right->isRed = false;
  }

  if (value < node->value) {
    AddResult child = add(node->left, value);
    node->left = child.node;
    if (child.needsFix) {
      if (isRed(node->left->left)) {
        return {singleRotateRight(node), false};
      }
      return {doubleRotateRight(node), false};
    }
    return {node, node->isRed && isRed(node->left)};
  } else {
    AddResult child = add(node->right, value);
    node->right = child.node;
    if (child.needsFix) {
      if (isRed(node->right->right)) {
        return {singleRotateLeft(node), false};
      }
      return {doubleRotateLeft(node), false};
    }
    return {node, node->isRed && isRed(node->right)};
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
    AddResult inserted = add(root, arr[i]);
    root = inserted.node;
    root->isRed = false;
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
