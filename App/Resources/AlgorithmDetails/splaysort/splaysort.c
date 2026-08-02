#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

typedef struct Node {
  int key;
  struct Node *left;
  struct Node *right;
} Node;

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

Node *newNode(int key) {
  Node *node = malloc(sizeof(Node));
  node->key = key;
  node->left = NULL;
  node->right = NULL;
  return node;
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
  if (root == NULL) {
    return root;
  }
  if (root->key > key) {
    if (root->left == NULL) {
      return root;
    }
    if (root->left->key > key) {
      root->left->left = splay(root->left->left, key);
      root = rightRotate(root);
    } else {
      root->left->right = splay(root->left->right, key);
      if (root->left->right != NULL) {
        root->left = leftRotate(root->left);
      }
    }
    return root->left == NULL ? root : rightRotate(root);
  } else {
    if (root->right == NULL) {
      return root;
    }
    if (root->right->key > key) {
      root->right->left = splay(root->right->left, key);
      if (root->right->left != NULL) {
        root->right = rightRotate(root->right);
      }
    } else {
      root->right->right = splay(root->right->right, key);
      root = leftRotate(root);
    }
    return root->right == NULL ? root : leftRotate(root);
  }
}

Node *insertRec(Node *root, int key) {
  if (root == NULL) {
    return newNode(key);
  }
  root = splay(root, key);
  Node *n = newNode(key);
  if (root->key > key) {
    n->right = root;
    n->left = root->left;
    root->left = NULL;
  } else {
    n->left = root;
    n->right = root->right;
    root->right = NULL;
  }
  return n;
}

void traverse(Node *node, int result[], int *idx) {
  if (node != NULL) {
    traverse(node->left, result, idx);
    result[*idx] = node->key;
    (*idx)++;
    traverse(node->right, result, idx);
  }
}

void freeTree(Node *node) {
  if (node != NULL) {
    freeTree(node->left);
    freeTree(node->right);
    free(node);
  }
}

void sort(int arr[], int n) {
  Node *root = NULL;
  for (int i = 0; i < n; i++) {
    root = insertRec(root, arr[i]);
  }
  int *result = malloc(sizeof(int) * n);
  int idx = 0;
  traverse(root, result, &idx);
  for (int i = 0; i < n; i++) {
    arr[i] = result[i];
  }
  free(result);
  freeTree(root);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
