#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

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

int height(int node) {
  int count = 0;
  while ((node >> count) % 2 == 1) {
    count += 1;
  }
  return count;
}

void thrift(int node, int parentFlag, int rootFlag) {
  int isRoot = rootFlag && (node >= (1 << height(node)));
  if (!isRoot && !parentFlag) {
    return;
  }

  int choice = height(node) - (isRoot ? 0 : 1);
  if (parentFlag) {
    for (int child = choice - 1; child >= 0; child--) {
      if (array[node - (1 << choice)] <= array[node - (1 << child)]) {
        choice = child;
      }
    }
  }

  if (array[node - (1 << choice)] <= array[node]) {
    return;
  }

  int t = array[node];
  array[node] = array[node - (1 << choice)];
  array[node - (1 << choice)] = t;
  int nextNode = node - (1 << choice);
  thrift(nextNode, nextNode % 2 == 1, choice == height(node));
}

void sort(int arr[], int n) {
  int node = 1;
  while (node < n) {
    thrift(node, node % 2 == 1, (node + (1 << height(node))) >= n);
    node += 1;
  }

  node -= (node - 1) % 2;
  while (node > 2) {
    for (int child = height(node) - 1; child >= 0; child--) {
      thrift(node - (1 << child), 0, 1);
    }
    node -= 2;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
