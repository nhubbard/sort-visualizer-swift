#include <cstdio>
#include <utility>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

void printList(int arr[], int n) {
  for (int i = 0; i < n; i++) {
    if (i == 0) {
      printf("[%d, ", arr[i]);
    } else if (i != n - 1) {
      printf("%d, ", arr[i]);
    } else {
      printf("%d]", arr[i]);
    }
  }
}

int height(int node) {
  int count = 0;
  while ((node >> count) % 2 == 1) {
    count++;
  }
  return count;
}

void thrift(int node, bool parentFlag, bool rootFlag) {
  bool isRoot = rootFlag && (node >= (1 << height(node)));
  if (!isRoot && !parentFlag) {
    return;
  }

  int choice = height(node) - (isRoot ? 0 : 1);
  if (parentFlag) {
    int bound = choice;
    for (int child = bound - 1; child >= 0; child--) {
      if (array[node - (1 << choice)] <= array[node - (1 << child)]) {
        choice = child;
      }
    }
  }

  if (array[node - (1 << choice)] <= array[node]) {
    return;
  }

  std::swap(array[node], array[node - (1 << choice)]);
  int nextNode = node - (1 << choice);
  thrift(nextNode, nextNode % 2 == 1, choice == height(node));
}

void sort(int arr[], int n) {
  int node = 1;
  while (node < n) {
    thrift(node, node % 2 == 1, (node + (1 << height(node))) >= n);
    node++;
  }

  node -= (node - 1) % 2;
  while (node > 2) {
    for (int child = height(node) - 1; child >= 0; child--) {
      thrift(node - (1 << child), false, true);
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
