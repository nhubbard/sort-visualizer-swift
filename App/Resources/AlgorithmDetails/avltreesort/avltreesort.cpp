#include <cstdio>
#include <vector>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

struct Node {
  int value;
  Node *left;
  Node *right;
  int balance;

  explicit Node(int value)
      : value(value), left(nullptr), right(nullptr), balance(0) {}
};

struct AddResult {
  Node *node;
  bool heightChanged;
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

Node *singleRotateRight(Node *node) {
  Node *b = node->left;
  node->left = b->right;
  b->right = node;
  node->balance = 0;
  b->balance = 0;
  return b;
}

Node *singleRotateLeft(Node *node) {
  Node *b = node->right;
  node->right = b->left;
  b->left = node;
  node->balance = 0;
  b->balance = 0;
  return b;
}

Node *doubleRotateRight(Node *node) {
  int oldBBalance = node->left->right->balance;
  node->left = singleRotateLeft(node->left);
  Node *b = singleRotateRight(node);
  if (oldBBalance == -1) {
    b->right->balance = 1;
  }
  if (oldBBalance == 1) {
    b->left->balance = -1;
  }
  return b;
}

Node *doubleRotateLeft(Node *node) {
  int oldBBalance = node->right->left->balance;
  node->right = singleRotateRight(node->right);
  Node *b = singleRotateLeft(node);
  if (oldBBalance == -1) {
    b->right->balance = 1;
  }
  if (oldBBalance == 1) {
    b->left->balance = -1;
  }
  return b;
}

AddResult heightChangeLeft(Node *node) {
  if (node->balance != -1) {
    node->balance -= 1;
    return {node, node->balance == -1};
  }
  if (node->left->balance == -1) {
    return {singleRotateRight(node), false};
  }
  return {doubleRotateRight(node), false};
}

AddResult heightChangeRight(Node *node) {
  if (node->balance != 1) {
    node->balance += 1;
    return {node, node->balance == 1};
  }
  if (node->right->balance == 1) {
    return {singleRotateLeft(node), false};
  }
  return {doubleRotateLeft(node), false};
}

AddResult add(Node *node, int value) {
  if (node == nullptr) {
    return {new Node(value), true};
  }
  if (value < node->value) {
    AddResult result = add(node->left, value);
    node->left = result.node;
    if (result.heightChanged) {
      return heightChangeLeft(node);
    }
    return {node, false};
  } else {
    AddResult result = add(node->right, value);
    node->right = result.node;
    if (result.heightChanged) {
      return heightChangeRight(node);
    }
    return {node, false};
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
    root = add(root, arr[i]).node;
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
