#include <cmath>
#include <cstdio>
#include <utility>

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

void sort(int arr[], int n) {
  if (n <= 1) {
    return;
  }
  int pow2 = (int)(std::log(n - 1) / std::log(2));
  for (int k = pow2; k >= 0; k--) {
    int pow3 = (int)((std::log(n) - k * std::log(2)) / std::log(3));
    for (int j = pow3; j >= 0; j--) {
      int gap = (int)(std::pow(2, k) * std::pow(3, j));
      for (int i = 0; i + gap < n; i++) {
        if (arr[i] > arr[i + gap]) {
          std::swap(arr[i], arr[i + gap]);
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
