#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

typedef struct Node {
  int value;
  struct Node *left;
  struct Node *right;
  int balance;
} Node;

typedef struct {
  Node *node;
  int heightChanged;
} AddResult;

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

Node *newNode(int value) {
  Node *node = malloc(sizeof(Node));
  node->value = value;
  node->left = NULL;
  node->right = NULL;
  node->balance = 0;
  return node;
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
    AddResult result = {node, node->balance == -1};
    return result;
  }
  if (node->left->balance == -1) {
    AddResult result = {singleRotateRight(node), 0};
    return result;
  }
  AddResult result = {doubleRotateRight(node), 0};
  return result;
}

AddResult heightChangeRight(Node *node) {
  if (node->balance != 1) {
    node->balance += 1;
    AddResult result = {node, node->balance == 1};
    return result;
  }
  if (node->right->balance == 1) {
    AddResult result = {singleRotateLeft(node), 0};
    return result;
  }
  AddResult result = {doubleRotateLeft(node), 0};
  return result;
}

AddResult add(Node *node, int value) {
  if (node == NULL) {
    AddResult result = {newNode(value), 1};
    return result;
  }
  if (value < node->value) {
    AddResult left = add(node->left, value);
    node->left = left.node;
    if (left.heightChanged) {
      return heightChangeLeft(node);
    }
    AddResult result = {node, 0};
    return result;
  } else {
    AddResult right = add(node->right, value);
    node->right = right.node;
    if (right.heightChanged) {
      return heightChangeRight(node);
    }
    AddResult result = {node, 0};
    return result;
  }
}

void traverse(Node *node, int result[], int *idx) {
  if (node == NULL) {
    return;
  }
  traverse(node->left, result, idx);
  result[(*idx)++] = node->value;
  traverse(node->right, result, idx);
}

void freeTree(Node *node) {
  if (node == NULL) {
    return;
  }
  freeTree(node->left);
  freeTree(node->right);
  free(node);
}

void sort(int arr[], int n) {
  Node *root = NULL;
  for (int i = 0; i < n; i++) {
    AddResult added = add(root, arr[i]);
    root = added.node;
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
