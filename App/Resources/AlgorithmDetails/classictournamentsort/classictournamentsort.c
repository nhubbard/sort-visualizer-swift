#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

int ceilPow2(int value) {
  int r = 1;
  while (r < value) {
    r *= 2;
  }
  return r;
}

void sort(int arr[], int n) {
  if (n <= 1)
    return;

  int size = ceilPow2(n) - 1;
  int mod = n % 2;
  int treeSize = n + size + mod;
  int *tree = malloc(sizeof(int) * treeSize);
  for (int i = 0; i < treeSize; i++) {
    tree[i] = -1;
  }

  for (int i = size; i < treeSize - mod; i++) {
    tree[i] = i - size;
  }

  int j = size;
  int k = treeSize - mod;
  while (j > 0) {
    int i = j;
    while (i + 1 < k) {
      tree[i / 2] = (arr[tree[i]] <= arr[tree[i + 1]]) ? tree[i] : tree[i + 1];
      i += 2;
    }
    if (i < k) {
      tree[i / 2] = tree[i];
    }
    j /= 2;
    k /= 2;
  }

  int *output = malloc(sizeof(int) * n);
  output[0] = arr[tree[0]];

  for (int idx = 1; idx < n; idx++) {
    int path = tree[0] + size;
    while (path > 0) {
      tree[path] = -1;
      path = (path - 1) / 2;
    }

    int node = tree[0] + size;
    while (node > 0) {
      int sibling = (node % 2 == 1) ? node + 1 : node - 1;
      int nodeValid = tree[node] != -1;
      int siblingValid = tree[sibling] != -1;
      int winner;
      if (nodeValid && siblingValid) {
        if (node < sibling) {
          winner = (arr[tree[node]] <= arr[tree[sibling]]) ? tree[node]
                                                           : tree[sibling];
        } else {
          winner = (arr[tree[sibling]] <= arr[tree[node]]) ? tree[sibling]
                                                           : tree[node];
        }
      } else if (nodeValid) {
        winner = tree[node];
      } else if (siblingValid) {
        winner = tree[sibling];
      } else {
        winner = -1;
      }
      node = (node - 1) / 2;
      if (winner != -1) {
        tree[node] = winner;
      }
    }
    output[idx] = arr[tree[0]];
  }

  for (int idx = 0; idx < n; idx++) {
    arr[idx] = output[idx];
  }
  free(output);
  free(tree);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
