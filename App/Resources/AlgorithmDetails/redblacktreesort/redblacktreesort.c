#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

typedef struct Node {
  int value;
  struct Node *left;
  struct Node *right;
  int isRed;
} Node;

typedef struct AddResult {
  Node *node;
  int needsFix;
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
  node->isRed = 1;
  return node;
}

int isRed(Node *node) { return node != NULL && node->isRed; }

Node *singleRotateRight(Node *node) {
  Node *b = node->left;
  node->left = b->right;
  b->right = node;
  b->isRed = 0;
  node->isRed = 1;
  return b;
}

Node *singleRotateLeft(Node *node) {
  Node *b = node->right;
  node->right = b->left;
  b->left = node;
  b->isRed = 0;
  node->isRed = 1;
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
  if (node == NULL) {
    AddResult inserted = {newNode(value), 0};
    return inserted;
  }

  if (!node->isRed && isRed(node->left) && isRed(node->right)) {
    node->isRed = 1;
    node->left->isRed = 0;
    node->right->isRed = 0;
  }

  if (value < node->value) {
    AddResult child = add(node->left, value);
    node->left = child.node;
    if (child.needsFix) {
      if (isRed(node->left->left)) {
        AddResult done = {singleRotateRight(node), 0};
        return done;
      }
      AddResult done = {doubleRotateRight(node), 0};
      return done;
    }
    AddResult done = {node, node->isRed && isRed(node->left)};
    return done;
  } else {
    AddResult child = add(node->right, value);
    node->right = child.node;
    if (child.needsFix) {
      if (isRed(node->right->right)) {
        AddResult done = {singleRotateLeft(node), 0};
        return done;
      }
      AddResult done = {doubleRotateLeft(node), 0};
      return done;
    }
    AddResult done = {node, node->isRed && isRed(node->right)};
    return done;
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
    AddResult inserted = add(root, arr[i]);
    root = inserted.node;
    root->isRed = 0;
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
