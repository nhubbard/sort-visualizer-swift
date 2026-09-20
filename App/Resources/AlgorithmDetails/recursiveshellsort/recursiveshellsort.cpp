#include <cstdio>

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

void gappedInsertionSort(int arr[], int a, int b, int gap);
void recursiveShellSort(int arr[], int start, int end, int g);

void sort(int arr[], int length) {
  recursiveShellSort(arr, 0, length, 1);
}

void gappedInsertionSort(int arr[], int a, int b, int gap) {
  for (int i = a + gap; i < b; i += gap) {
    int j = i;
    while (j - gap >= a && arr[j] < arr[j - gap]) {
      int temp = arr[j];
      arr[j] = arr[j - gap];
      arr[j - gap] = temp;
      j -= gap;
    }
  }
}

void recursiveShellSort(int arr[], int start, int end, int g) {
  if (start + g <= end) {
    recursiveShellSort(arr, start, end, 3 * g);
    recursiveShellSort(arr, start + g, end, 3 * g);
    recursiveShellSort(arr, start + (2 * g), end, 3 * g);
    gappedInsertionSort(arr, start, end, g);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
