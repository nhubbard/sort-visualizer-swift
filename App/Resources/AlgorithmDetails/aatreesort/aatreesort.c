#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

typedef struct Node {
  int value;
  int level;
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

Node *newNode(int value) {
  Node *node = malloc(sizeof(Node));
  node->value = value;
  node->level = 0;
  node->left = NULL;
  node->right = NULL;
  return node;
}

int nodeLevel(Node *node) { return node == NULL ? -1 : node->level; }

Node *skew(Node *node) {
  if (node->left == NULL) {
    return node;
  }
  Node *l = node->left;
  node->left = l->right;
  l->right = node;
  return l;
}

Node *split(Node *node) {
  if (node->right == NULL) {
    return node;
  }
  Node *r = node->right;
  node->right = r->left;
  r->left = node;
  r->level++;
  return r;
}

Node *add(Node *node, int value) {
  if (node == NULL) {
    return newNode(value);
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
    root = add(root, arr[i]);
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
