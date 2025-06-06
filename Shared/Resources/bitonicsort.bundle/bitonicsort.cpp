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
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}