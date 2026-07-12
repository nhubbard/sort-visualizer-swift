#include <stdio.h>

void sort(int array[], int currentLen) {
  for (int i = 0; i < currentLen; i++) {
    int shortest = i;

    int j = i;
    while (j < currentLen) {
      int isShortest = 1;
      int k = j + 1;
      while (k < currentLen) {
        if (array[j] > array[k]) {
          isShortest = 0;
          break;
        }
        k++;
      }
      if (isShortest) {
        shortest = j;
        break;
      }
      j++;
    }

    int temp = array[i];
    array[i] = array[shortest];
    array[shortest] = temp;
  }
}

void printList(int arr[], int n) {
  for (int i = 0; i < n; i++) {
    if (i == 0) {
      printf("[%d, ", arr[i]);
    } else if (i != n - 1) {
      printf("%d, ", arr[i]);
    } else {
      printf("%d]\n", arr[i]);
    }
  }
}

int main(void) {
  int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                   90, 69, 51, 81, 68, 83, 32, 56};
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
