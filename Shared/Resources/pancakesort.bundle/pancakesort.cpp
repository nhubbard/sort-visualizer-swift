#include <cstdio>
#include <utility>

int items[10] = {35, 95, 74, 71, 72, 30, 96, 53, 9, 0};

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

void flip(int arr[], int n) {
  int left = 0;
  while (left < n) {
    std::swap(arr[left], arr[n]);
    n--;
    left++;
  }
}

int maxIndex(int arr[], int n) {
  int index = 0;
  for (int i = 0; i < n; i++) {
    if (arr[i] > arr[index]) {
      index = i;
    }
  }
  return index;
}

void pancakeSort(int arr[], int n) {
  int max;
  while (n > 1) {
    max = maxIndex(arr, n);
    if (max != n) {
      flip(arr, max);
      flip(arr, n - 1);
    }
    n--;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(items) / sizeof(items[0]);
  pancakeSort(items, size);
  printList(items, size);
  return 0;
}
