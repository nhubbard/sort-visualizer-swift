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

void swaplessBubbleSort(int arr[], int n);

void sort(int arr[], int n) {
  swaplessBubbleSort(arr, n);
}

void swaplessBubbleSort(int arr[], int n) {
  int i = n;
  while (i > 0) {
    int last = 0;
    int pos = 0;
    int comp = arr[0];
    for (int j = 1; j < i; j++) {
      if (comp > arr[j]) {
        arr[j - 1] = arr[j];
        last = j;
      } else {
        if (pos + 1 < j) {
          arr[j - 1] = comp;
        }
        pos = j;
        comp = arr[j];
      }
    }
    arr[i - 1] = comp;
    i = last;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
