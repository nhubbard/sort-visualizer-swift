#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

typedef struct Node {
  int pointer;
  struct Node *left;
  struct Node *right;
} Node;

void printList(int items[], int size) {
  printf("[");
  if (size > 0) {
    printf("%d", items[0]);
    for (int i = 1; i < size; i++) {
      printf(", %d", items[i]);
    }
  }
  printf("]");
}

Node *newNode(int pointer);
Node *add(int arr[], Node *node, int addPtr);
void traverse(int arr[], Node *node, int result[], int *idx);
void freeTree(Node *node);

void sort(int arr[], int n) {
  Node *root = NULL;
  for (int i = 0; i < n; i++) {
    root = add(arr, root, i);
  }

  int *result = malloc(sizeof(int) * n);
  int idx = 0;
  traverse(arr, root, result, &idx);

  for (int i = 0; i < n; i++) {
    arr[i] = result[i];
  }

  free(result);
  freeTree(root);
}

Node *newNode(int pointer) {
  Node *node = malloc(sizeof(Node));
  node->pointer = pointer;
  node->left = NULL;
  node->right = NULL;
  return node;
}

Node *add(int arr[], Node *node, int addPtr) {
  if (node == NULL) {
    return newNode(addPtr);
  }
  if (arr[addPtr] < arr[node->pointer]) {
    node->left = add(arr, node->left, addPtr);
  } else {
    node->right = add(arr, node->right, addPtr);
  }
  return node;
}

void traverse(int arr[], Node *node, int result[], int *idx) {
  if (node == NULL) {
    return;
  }
  traverse(arr, node->left, result, idx);
  result[(*idx)++] = arr[node->pointer];
  traverse(arr, node->right, result, idx);
}

void freeTree(Node *node) {
  if (node == NULL) {
    return;
  }
  freeTree(node->left);
  freeTree(node->right);
  free(node);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
