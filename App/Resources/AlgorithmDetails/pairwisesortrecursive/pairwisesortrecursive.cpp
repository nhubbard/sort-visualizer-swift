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

void compSwap(int arr[], int a, int b);
void pairwiseRecursive(int arr[], int start, int end, int gap);

void sort(int arr[], int n) {
  if (n <= 1) return;
  pairwiseRecursive(arr, 0, n, 1);
}

void compSwap(int arr[], int a, int b) {
  if (arr[a] > arr[b]) {
    std::swap(arr[a], arr[b]);
  }
}

void pairwiseRecursive(int arr[], int start, int end, int gap) {
  if (start == end - gap) {
    return;
  }
  int b = start + gap;
  while (b < end) {
    compSwap(arr, b - gap, b);
    b += 2 * gap;
  }

  if (((end - start) / gap) % 2 == 0) {
    pairwiseRecursive(arr, start, end, gap * 2);
    pairwiseRecursive(arr, start + gap, end + gap, gap * 2);
  } else {
    pairwiseRecursive(arr, start, end + gap, gap * 2);
    pairwiseRecursive(arr, start + gap, end, gap * 2);
  }

  int a = 1;
  while (a < (end - start) / gap) {
    a = (a * 2) + 1;
  }

  b = start + gap;
  while (b + gap < end) {
    int c = a;
    while (c > 1) {
      c /= 2;
      if (b + (c * gap) < end) {
        compSwap(arr, b, b + (c * gap));
      }
    }
    b += 2 * gap;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
