#include <algorithm>
#include <cmath>
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

void maxToFront(int arr[], int a, int b);

void sort(int arr[], int n) {
  if (n <= 1) return;
  int s = static_cast<int>(std::sqrt(static_cast<double>(n - 1))) + 1;

  int i = 0;
  while (i < n) {
    maxToFront(arr, i, std::min(i + s, n));
    i += s;
  }

  int j = n;
  while (j > 0) {
    int best = 0;
    int k = best + s;
    while (k < j) {
      if (arr[k] >= arr[best]) {
        best = k;
      }
      k += s;
    }
    j--;
    std::swap(arr[best], arr[j]);
    maxToFront(arr, best, std::min(best + s, j));
  }
}

void maxToFront(int arr[], int a, int b) {
  int best = a;
  int i = a + 1;
  while (i < b) {
    if (arr[i] > arr[best]) {
      best = i;
    }
    i++;
  }
  std::swap(arr[best], arr[a]);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
