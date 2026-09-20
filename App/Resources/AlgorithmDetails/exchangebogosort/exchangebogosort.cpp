#include <cstdio>
#include <cstdlib>

int array[8] = {0, 39, 21, 62, 91, 77, 14, 23};

inline void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

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

inline bool isSorted(int arr[], int n);

void sort(int arr[], int n) {
  while (!isSorted(arr, n)) {
    int i = rand() % n;
    int j = rand() % n;
    if ((i < j && arr[i] > arr[j]) || (i > j && arr[i] < arr[j]))
      swap(&arr[i], &arr[j]);
  }
}

inline bool isSorted(int arr[], int n) {
  while (--n >= 1)
    if (arr[n] < arr[n - 1])
      return false;
  return true;
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
