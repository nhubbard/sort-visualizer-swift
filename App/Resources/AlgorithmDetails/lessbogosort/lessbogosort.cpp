#include <cstdio>
#include <cstdlib>
#include <utility>

int array[8] = {0, 39, 21, 62, 91, 77, 14, 23};

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

inline bool isMinimum(int arr[], int start, int end) {
  for (int k = start + 1; k < end; k++)
    if (arr[start] > arr[k])
      return false;
  return true;
}

inline void shuffleRange(int arr[], int start, int end) {
  for (int i = start; i < end - 1; i++)
    std::swap(arr[i], arr[i + rand() % (end - i)]);
}

void sort(int arr[], int n) {
  for (int i = 0; i < n; i++)
    while (!isMinimum(arr, i, n))
      shuffleRange(arr, i, n);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
