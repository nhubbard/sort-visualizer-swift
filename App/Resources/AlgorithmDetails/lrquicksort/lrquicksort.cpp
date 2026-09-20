#include <cstdio>
#include <utility>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

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

void quickSort(int arr[], int p, int r);

void sort(int arr[], int n) {
  quickSort(arr, 0, n - 1);
}

void quickSort(int arr[], int p, int r) {
  while (p < r) {
    int pivot = arr[p + (r - p + 1) / 2];
    int i = p;
    int j = r;
    while (i <= j) {
      while (arr[i] < pivot) i++;
      while (arr[j] > pivot) j--;
      if (i <= j) {
        std::swap(arr[i], arr[j]);
        i++;
        j--;
      }
    }
    if (j - p < r - i) {
      if (p < j) quickSort(arr, p, j);
      p = i;
    } else {
      if (i < r) quickSort(arr, i, r);
      r = j;
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
