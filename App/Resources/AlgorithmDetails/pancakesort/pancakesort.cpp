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

void sort(int arr[], int n) {
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
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}