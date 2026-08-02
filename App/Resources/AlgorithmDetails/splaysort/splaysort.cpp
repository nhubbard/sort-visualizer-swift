#include <cstdio>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

struct Node {
  int key;
  Node *left;
  Node *right;

  explicit Node(int key) : key(key), left(nullptr), right(nullptr) {}
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

Node *leftRotate(Node *x) {
  Node *y = x->right;
  x->right = y->left;
  y->left = x;
  return y;
}

Node *rightRotate(Node *x) {
  Node *y = x->left;
  x->left = y->right;
  y->right = x;
  return y;
}

Node *splay(Node *root, int key) {
  if (root == nullptr) {
    return root;
  }
  if (root->key > key) {
    if (root->left == nullptr) {
      return root;
    }
    if (root->left->key > key) {
      root->left->left = splay(root->left->left, key);
      root = rightRotate(root);
    } else {
      root->left->right = splay(root->left->right, key);
      if (root->left->right != nullptr) {
        root->left = leftRotate(root->left);
      }
    }
    return root->left == nullptr ? root : rightRotate(root);
  } else {
    if (root->right == nullptr) {
      return root;
    }
    if (root->right->key > key) {
      root->right->left = splay(root->right->left, key);
      if (root->right->left != nullptr) {
        root->right = rightRotate(root->right);
      }
    } else {
      root->right->right = splay(root->right->right, key);
      root = leftRotate(root);
    }
    return root->right == nullptr ? root : leftRotate(root);
  }
}

Node *insertRec(Node *root, int key) {
  if (root == nullptr) {
    return new Node(key);
  }
  root = splay(root, key);
  Node *n = new Node(key);
  if (root->key > key) {
    n->right = root;
    n->left = root->left;
    root->left = nullptr;
  } else {
    n->left = root;
    n->right = root->right;
    root->right = nullptr;
  }
  return n;
}

void traverse(Node *node, int result[], int *idx) {
  if (node != nullptr) {
    traverse(node->left, result, idx);
    result[*idx] = node->key;
    (*idx)++;
    traverse(node->right, result, idx);
  }
}

void freeTree(Node *node) {
  if (node != nullptr) {
    freeTree(node->left);
    freeTree(node->right);
    delete node;
  }
}

void sort(int arr[], int n) {
  Node *root = nullptr;
  for (int i = 0; i < n; i++) {
    root = insertRec(root, arr[i]);
  }
  int *result = new int[n];
  int idx = 0;
  traverse(root, result, &idx);
  for (int i = 0; i < n; i++) {
    arr[i] = result[i];
  }
  delete[] result;
  freeTree(root);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
