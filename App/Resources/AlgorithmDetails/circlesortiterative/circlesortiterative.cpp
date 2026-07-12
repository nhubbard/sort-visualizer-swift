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

int circleSortRoutine(int arr[], int length, int end) {
  int swapCount = 0;
  for (int gap = length / 2; gap > 0; gap /= 2) {
    for (int start = 0; start + gap < end; start += 2 * gap) {
      int low = start;
      int high = start + 2 * gap - 1;
      while (low < high) {
        if (high < end && arr[low] > arr[high]) {
          std::swap(arr[low], arr[high]);
          swapCount++;
        }
        low++;
        high--;
      }
    }
  }
  return swapCount;
}

void sort(int arr[], int size) {
  if (size <= 1) return;
  int n = 1;
  while (n < size) {
    n <<= 1;
  }

  int numberOfSwaps = 1;
  while (numberOfSwaps != 0) {
    numberOfSwaps = circleSortRoutine(arr, n, size);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
