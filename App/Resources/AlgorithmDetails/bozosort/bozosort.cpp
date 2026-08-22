#include <cstdio>
#include <cstdlib>

int array[6] = {0, 39, 21, 62, 91, 77};

inline void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

void printList(int items[], int size) {
  for (int i = 0; i < size; i++) {
    if (i == 0)
      printf("[%d, ", items[i]);
    else if (i != size - 1)
      printf("%d, ", items[i]);
    else
      printf("%d]", items[i]);
  }
}

inline bool isSorted(int arr[], int n) {
  for (int i = 1; i < n; i++)
    if (arr[i - 1] > arr[i])
      return false;
  return true;
}

void sort(int arr[], int n) {
  while (!isSorted(arr, n)) {
    int i = rand() % n;
    int j = rand() % n;
    swap(&arr[i], &arr[j]);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
