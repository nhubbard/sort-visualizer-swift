#include <cstdio>
#include <cstdlib>

int array[8] = {0, 39, 21, 62, 91, 77, 14, 23};

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
  while (--n >= 1)
    if (arr[n] < arr[n - 1])
      return false;
  return true;
}

void sort(int arr[], int n) {
  while (!isSorted(arr, n))
    for (int i = 0; i < n; i++)
      swap(&arr[i], &arr[rand() % n]);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
