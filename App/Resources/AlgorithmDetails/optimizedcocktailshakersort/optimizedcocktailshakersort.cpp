#include <cstdio>
#include <utility>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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
  int start = 0;
  int end = n - 1;
  while (start < end) {
    int consecSorted = 1;
    for (int i = start; i < end; i++) {
      if (arr[i] > arr[i + 1]) {
        std::swap(arr[i], arr[i + 1]);
        consecSorted = 1;
      } else {
        consecSorted++;
      }
    }
    end -= consecSorted;

    consecSorted = 1;
    for (int j = end; j > start; j--) {
      if (arr[j - 1] > arr[j]) {
        std::swap(arr[j - 1], arr[j]);
        consecSorted = 1;
      } else {
        consecSorted++;
      }
    }
    start += consecSorted;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
