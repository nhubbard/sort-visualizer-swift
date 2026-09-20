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

bool is3Smooth(int n);

void sort(int arr[], int n) {
  for (int g = n - 1; g > 0; g--) {
    if (is3Smooth(g)) {
      for (int i = g; i < n; i++) {
        if (arr[i - g] > arr[i]) {
          std::swap(arr[i - g], arr[i]);
        }
      }
    }
  }
}

bool is3Smooth(int n) {
  while (n % 6 == 0) {
    n /= 6;
  }
  while (n % 3 == 0) {
    n /= 3;
  }
  while (n % 2 == 0) {
    n /= 2;
  }
  return n == 1;
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
