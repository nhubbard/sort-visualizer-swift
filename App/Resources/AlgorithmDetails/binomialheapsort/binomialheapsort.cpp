#include <cstdio>
#include <utility>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

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

void sort(int arr[], int n) {
  int index = 2;
  while (index <= n) {
    int maxNode = index;
    while (true) {
      int focus = maxNode;
      int depth = 1;
      while ((focus & depth) == 0) {
        if (arr[focus - depth - 1] > arr[maxNode - 1]) {
          maxNode = focus - depth;
        }
        depth *= 2;
      }
      if (focus != maxNode) {
        std::swap(arr[focus - 1], arr[maxNode - 1]);
      }
      if (focus == maxNode) {
        break;
      }
    }
    index += 2;
  }

  index = n;
  while (index > 2) {
    int maxNode = index;
    int focus = index;
    int depth = 1;
    while (focus != 0) {
      if ((focus & depth) != 0) {
        if (arr[focus - 1] > arr[maxNode - 1]) {
          maxNode = focus;
        }
        focus -= depth;
      }
      depth *= 2;
    }

    if (maxNode != index) {
      focus = index;
      while (true) {
        std::swap(arr[focus - 1], arr[maxNode - 1]);
        focus = maxNode;
        int innerDepth = 1;
        while ((focus & innerDepth) == 0) {
          if (arr[focus - innerDepth - 1] > arr[maxNode - 1]) {
            maxNode = focus - innerDepth;
          }
          innerDepth *= 2;
        }
        if (focus == maxNode) {
          break;
        }
      }
    }
    index--;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
