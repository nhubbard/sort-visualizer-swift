#include <cstdio>
#include <utility>

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

void flip(int arr[], int end) {
  int start = 0;
  while (start < end) {
    std::swap(arr[start], arr[end]);
    start++;
    end--;
  }
}

void sort(int arr[], int n) {
  for (int i = n - 1; i > 0; i--) {
    int max = 0;
    for (int j = max + 1; j <= i; j++) {
      if (arr[j] > arr[max]) {
        max = j;
      }
    }
    if (max != i) {
      flip(arr, max);
      flip(arr, i);
      flip(arr, i - 1);
      flip(arr, max - 1);
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}