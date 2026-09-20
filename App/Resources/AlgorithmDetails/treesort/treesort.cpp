#include <cstdio>
#include <vector>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

struct Node {
  int pointer;
  Node *left;
  Node *right;

  explicit Node(int pointer)
      : pointer(pointer), left(nullptr), right(nullptr) {}
};

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

Node *add(int arr[], Node *node, int addPtr);
void traverse(int arr[], Node *node, std::vector<int> &result);
void freeTree(Node *node);

void sort(int arr[], int n) {
  Node *root = nullptr;
  for (int i = 0; i < n; i++) {
    root = add(arr, root, i);
  }

  std::vector<int> result;
  traverse(arr, root, result);

  for (int i = 0; i < n; i++) {
    arr[i] = result[i];
  }

  freeTree(root);
}

Node *add(int arr[], Node *node, int addPtr) {
  if (node == nullptr) {
    return new Node(addPtr);
  }
  if (arr[addPtr] < arr[node->pointer]) {
    node->left = add(arr, node->left, addPtr);
  } else {
    node->right = add(arr, node->right, addPtr);
  }
  return node;
}

void traverse(int arr[], Node *node, std::vector<int> &result) {
  if (node == nullptr) {
    return;
  }
  traverse(arr, node->left, result);
  result.push_back(arr[node->pointer]);
  traverse(arr, node->right, result);
}

void freeTree(Node *node) {
  if (node == nullptr) {
    return;
  }
  freeTree(node->left);
  freeTree(node->right);
  delete node;
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
