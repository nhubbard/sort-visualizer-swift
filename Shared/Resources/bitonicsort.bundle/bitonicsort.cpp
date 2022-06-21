#include <cstdio>
#include <utility>

// Specific to bitonic sort: size must be power of 2.
int items[8] = {35, 74, 71, 72, 30, 53, 9, 0};

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

void sort(int arr[], int n) {
  for (int k = 2; k <= n; k *= 2) {
    for (int j = k / 2; j > 0; j /= 2) {
      for (int i = 0; i < n; i++) {
        int l = i ^ j;
        if (l > i) {
          if (((i & k) == 0) && (arr[i] > arr[l]) ||
              (((i & k) != 0) && (arr[i] < arr[l]))) {
            std::swap(arr[i], arr[l]);
          }
        }
      }
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(items) / sizeof(items[0]);
  sort(items, size);
  printList(items, size);
  return 0;
}
